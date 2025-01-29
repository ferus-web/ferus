import std/[os, logging, osproc, strutils, options, base64, net, sets, terminal, tables]
import ferus_ipc/server/prelude
import jsony
import ./summon
import pretty

# Process specific imports

# Network
import sanchar/parse/url
import sanchar/proto/http/shared

import ../../components/shared/[nix, sugar]
import
  ../../components/
    [network/ipc, renderer/ipc, parsers/html/ipc, parsers/html/document, js/ipc]
import ../../components/web/cookie/parsed_cookie

when defined(unix):
  import std/posix

type MasterProcess* = ref object
  server*: IPCServer
  urls*: Table[uint, URL]

proc initialize*(master: MasterProcess) {.inline.} =
  master.server.add(FerusGroup())
    # TODO: multi-tab support, although we could just keep adding more FerusGroup(s) and it should *theoretically* scale
  master.server.initialize()

proc poll*(master: MasterProcess) {.inline.} =
  master.server.poll()

proc launchAndWait(master: MasterProcess, summoned: string) =
  info "launchAndWait(\"" & summoned & "\"): starting execution of process."
  when defined(ferusJustWaitForConnection):
    master.server.acceptNewConnection()
    return

  when defined(unix):
    let
      original = getpid()
      forked = fork()

    if forked == 0:
      info "Running: " & summoned
      let res = execCmd(summoned)

      case res
      of 0:
        info "ferus_process exited out gracefully; ciao!"
      of 139:
        warn "ferus_process has crashed with a segmentation fault! (139)"
        warn "command: " & summoned
      of 1:
        warn "ferus_process has crashed with an unhandled error or defect! (1)"
        warn "command: " & summoned
      else:
        warn "ferus_process crashed with an unknown exit code: " & $res
        warn "command: " & summoned

      quit(res)
    elif forked < 0:
      error "Fork syscall failed!!!"
      quit(1)
    else:
      master.server.acceptNewConnection()

proc waitUntilReady*(
    master: MasterProcess,
    process: var FerusProcess,
    kind: FerusProcessKind,
    parserKind: ParserKind = pkCss,
    group: int = 0,
) {.inline.} =
  return

  var numWait: int

  while process.state in [Initialized, Processing]:
    info (
      "Waiting for $1 process to signal itself as ready for work #$2 (currently $3)" %
      [$kind, $numWait, $process.state]
    )
    master.server.poll()
    if (
      let o = master.server.groups[group].findProcess(kind, parserKind, workers = false)
      *o
    ):
      process = &o
    else:
      error "$1 process has disconnected before marking itself as ready! It probably crashed! D:" %
        [$kind]
      break

    inc numWait

  info "$1 process is now in $2 state, ending wait. It took $3 wait iterations to signal itself as ready." %
    [$kind, $process.state, $numWait]

proc summonNetworkProcess*(master: MasterProcess, group: uint) =
  if *master.server.groups[group.int].findProcess(Network, workers = false):
    return

  info "Summoning network process for group " & $group
  let summoned = summon(Network, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc summonHTMLParser*(master: MasterProcess, group: uint) =
  if *master.server.groups[group.int].findProcess(Parser, pkHTML, workers = false):
    return

  info "Summoning HTML parser process for group " & $group
  let summoned = summon(Parser, pkHTML, master.server.path).dispatch()
  master.launchAndWait(summoned)

proc parseHTML*(
    master: MasterProcess, group: uint, source: string
): Option[HTMLParseResult] =
  var
    process =
      master.server.groups[group.int].findProcess(Parser, pkHTML, workers = false)
    numWait: int

  if not *process:
    master.summonNetworkProcess(group)
    return master.parseHTML(group, source)

  var prc = &process
  master.waitUntilReady(prc, Parser, pkHTML)

  info ("Sending group $1 HTML parser process a request to parse some HTML" % [$group])

  master.server.send((&process).socket, ParseHTMLPacket(source: encode(source)))

  info ("Waiting for response from group $1 HTML parser process" % [$group])

  var
    numRecv: int
    res: Option[HTMLParseResult]

  while res.isNone:
    #info "Waiting for network process to send a `NetworkFetchResult` x" & $numRecv
    let packet = master.server.receive((&process).socket, HTMLParseResult)

    if not *packet:
      inc numRecv
      continue

    if *(&packet).document:
      res = packet
      break

    inc numRecv

  res

proc summonJSRuntime*(master: MasterProcess, group: uint) {.inline.} =
  if *master.server.groups[group.int].findProcess(JSRuntime, workers = false):
    return

  info "Summoning JS runtime process for group " & $group
  let summoned = summon(JSRuntime, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc summonRendererProcess*(master: MasterProcess) {.inline.} =
  info "Summoning renderer process."
  let summoned = summon(Renderer, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

  let oproc = master.server.groups[0].findProcess(Renderer, workers = false)
  if !oproc:
    error "Failed to spawn renderer process!"
    quit(1)

  # FIXME: investigate why this happens
  var process = &oproc
  let idx = master.server.groups[0].processes.find(process)

  process.state = Initialized
  master.server.groups[0].processes[idx] = process

proc renderDocument*(master: MasterProcess, document: HTMLDocument) =
  info "Dispatching the rendering of HTML document to the renderer process"
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.renderDocument(document)
    return

  var prc = &process
  assert prc.kind == Renderer
  master.server.send(prc.socket, RendererRenderDocument(document: document))

  info "Dispatched document to renderer process."

proc executeJS*(
    master: MasterProcess, group: uint, name: string = "<inline script>", code: string
) =
  info "Dispatching execution of JS code to runtime process"
  var process = master.server.groups[group.int].findProcess(JSRuntime, workers = false)

  if not *process:
    master.summonJSRuntime(group)
    master.executeJS(group, name = name, code = code)
    return

  var prc = &process
  assert prc.kind == JSRuntime
  master.server.send(
    prc.socket, JSExecPacket(name: name.encode(), buffer: code.encode())
  )

  info "Dispatching JS code to runtime process."

proc setWindowTitle*(master: MasterProcess, title: string) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.setWindowTitle(title)
    return

  var prc = &process
  # master.waitUntilReady(prc, Renderer)

  master.server.send(
    (&process).socket,
    RendererSetWindowTitle(
      title: title.encode(safe = true) # So that we can get spaces
    ),
  )

proc updateDocumentState*(master: MasterProcess, group: uint, document: HTMLDocument) =
  ## Send over a document to a JS process to update its internal version of it
  var process = master.server.groups[group.int].findProcess(JSRuntime, workers = false)

  if not *process:
    master.summonJSRuntime(group)
    master.updateDocumentState(group = group, document = document)
    return

  var prc = &process
  assert prc.kind == JSRuntime
  master.server.send(prc.socket, JSTakeDocument(document: document))

#proc cacheCookie*(master: MasterProcess, cookie: ParsedCookie)

proc dispatchRender*(master: MasterProcess, list: IPCDisplayList) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.dispatchRender(list)
    return

  var prc = &process
  # master.waitUntilReady(prc, Renderer)

  master.server.send((&process).socket, RendererMutationPacket(list: list))

proc loadFont*(
    master: MasterProcess, file, name: string, recursion: int = 0
) {.inline.} =
  var
    process = master.server.groups[0].findProcess(Renderer, workers = false)
    numRecursions = recursion

  if not *process:
    master.summonRendererProcess()
    master.loadFont(file, name, numRecursions + 1)
    return

  let ext = file.splitFile().ext

  var prc = &process

  info ("Sending renderer process a font to load: $1 as \"$2\"" % [file, name])
  let encoded = encode(
    # encode the data in base64 to ensure that it doesn't mess up the JSON packet
    readFile file, safe = true
  )
  master.server.send(
    (&process).socket,
    RendererLoadFontPacket(
      name: "Default", content: encoded, format: ext[1 ..< ext.len]
    ),
  )

proc fetchNetworkResource*(
    master: MasterProcess, group: uint, url: string
): Option[NetworkFetchResult] =
  var
    process = master.server.groups[group.int].findProcess(Network, workers = false)
    numWait: int

  if not *process:
    # process = master.summonNetworkProcess(group)
    master.summonNetworkProcess(group)
    return master.fetchNetworkResource(group, url)

  var prc = &process
  master.waitUntilReady(prc, Network)

  info (
    "Sending group $1 network process a request to fetch data from $2" % [$group, $url]
  )
  master.server.send((&process).socket, NetworkFetchPacket(url: parse url))

  info ("Waiting for response from group $1 network process" % [$group])

  var
    numRecv: int
    res: Option[NetworkFetchResult]

  while not *res:
    #info "Waiting for network process to send a `NetworkFetchResult` x" & $numRecv
    var count: cint
    discard nix.ioctl((&process).socket.getFd().cint, nix.FIONREAD, addr count)
    if count < 1:
      inc numRecv
      continue

    let packet = master.server.receive((&process).socket, NetworkFetchResult)

    if not *packet:
      inc numRecv
      continue

    let data = &packet
    if data.kind != feNetworkSendResult:
      inc numRecv
      continue

    if not *packet:
      inc numRecv
      continue

    if *(&packet).response:
      res = packet
      break

    inc numRecv

  res

proc dataTransfer*(
    master: MasterProcess, process: FerusProcess, request: DataTransferRequest
) =
  info "Data transfer request from " & $process.kind & " (PID " & $process.pid & ")"
  if request.location.kind == DataLocationKind.WebRequest:
    if process.kind != Renderer:
      master.server.reportBadMessage(
        process,
        "Process that does not require network data transfers (" & $process.kind &
          ") attempted to perform one.",
        High,
      )
      return

    var dest = request.location.url
    if not dest.startsWith("http") and not dest.startsWith("https"):
      dest = $master.urls[process.group] & dest

    let data = master.fetchNetworkResource(process.group, dest)

    if not *data:
      warn "Could not fulfill data transfer request as request to network process failed!"
      master.server.send(process.socket, DataTransferResult(success: false))
      return

    let resp = (&data).response

    if not *resp:
      warn "Could not fulfill data transfer as a server error occured!"
      master.server.send(process.socket, DataTransferResult(success: false))

    info "Received requested data from Network process, sending it to the " &
      $process.kind & " process"
    master.server.send(
      process.socket, DataTransferResult(success: true, data: (&resp).content)
    )
  else:
    warn "Unimplemented data transfer: FileRequest"

proc onConsoleLog*(
    master: MasterProcess, process: FerusProcess, data: JSConsoleMessage
) =
  styledWriteLine(
    stdout,
    "(",
    fgYellow,
    "Console",
    resetStyle,
    ") ",
    (
      case data.level
      of ConsoleLevel.Log: fgGreen
      of ConsoleLevel.Error: fgRed
      of ConsoleLevel.Debug: fgMagenta
      of ConsoleLevel.Info: fgBlue
      of ConsoleLevel.Trace: fgMagenta
      of ConsoleLevel.Warn: fgYellow
    ),
    data.message,
    resetStyle,
  )

proc packetHandler*(
    master: MasterProcess, process: FerusProcess, kind: FerusMagic, data: string
) =
  case kind
  of feJSConsoleMessage:
    let data = tryParseJson(data, JSConsoleMessage)

    if process.kind != JSRuntime:
      master.server.reportBadMessage(
        process, "Non-JS runtime process attempted to use `feJSConsoleMessage`!", High
      )
      return

    if !data:
      master.server.reportBadMessage(
        process,
        "Cannot reinterpret data for kind `feJSConsoleLog` as `JSConsoleMessage`", Low,
      )
      return

    master.onConsoleLog(process, &data)
  of feRendererGotoURL:
    let data = tryParseJson(data, RendererGotoURL)

    if process.kind != Renderer:
      master.server.reportBadMessage(
        process, "Non-renderer process attempted to use `feRendererGotoURL`!", High
      )
      return

    if !data:
      master.server.reportBadMessage(
        process,
        "Cannot reinterpret data for kind `feRendererGotoURL` as `RendererGotoURL`", Low,
      )
      return

    var location = (&data).url
    if not location.startsWith("http") and not location.startsWith("https"):
      let base = master.urls[process.group]
      location = base.scheme() & "://" & base.hostname() & '/' & location

    master.urls[process.group] = parse(location)
  else:
    warn "Unhandled IPC protocol magic: " & $kind
    return

proc newMasterProcess*(): MasterProcess {.inline.} =
  var master = MasterProcess(server: newIPCServer())

  master.server.onDataTransfer = proc(
      process: FerusProcess, request: DataTransferRequest
  ) =
    master.dataTransfer(process, request)

  master.server.handler = proc(process: FerusProcess, kind: FerusMagic, data: string) =
    master.packetHandler(process, kind, data)

  master
