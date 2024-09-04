import std/[os, logging, osproc, strutils, options, base64, sets]
import ferus_ipc/server/prelude
import jsony
import ./summon
import pretty

# Process specific imports

# Network
import sanchar/parse/url
import sanchar/proto/http/shared

import ../../components/[network/ipc, renderer/ipc, cookie_worker/ipc, parsers/html/ipc, parsers/html/document]
import ../../components/web/cookie/parsed_cookie

when defined(unix):
  import std/posix

type MasterProcess* = ref object
  server*: IPCServer

proc initialize*(master: MasterProcess) {.inline.} =
  master.server.add(FerusGroup()) # TODO: multi-tab support, although we could just keep adding more FerusGroup(s) and it should *theoretically* scale
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
      let (output, res) = execCmdEx(summoned)

      case res
      of 0:
        info "ferus_process exited out gracefully; ciao!"
        warn output
      of 139:
        warn "ferus_process has crashed with a segmentation fault (139)"
        warn output
      of 1:
        warn "ferus_process has crashed with an unhandled error or defect (1)"
        warn output
      else: warn "ferus_process crashed with an unknown exit code: " & $res

      quit(res)
    elif forked < 0:
      error "Fork syscall failed!!!"
      quit(1)
    else:
      master.server.acceptNewConnection()

proc waitUntilReady*(
  master: MasterProcess, 
  process: var FerusProcess,
  kind: FerusProcessKind, parserKind: ParserKind = pkCss, group: int = 0
) {.inline.} =
  var numWait: int
  let og = deepcopy process.kind

  while process.state in [Initialized, Processing]:
    #info ("Waiting for $1 process to signal itself as ready for work #$2 (currently $3)" % [$kind, $numWait, $process.state])
    master.server.poll()
    if (let o = master.server.groups[group].findProcess(kind, parserKind, workers = false); *o):
      process = &o
    else:
      error "$1 process has disconnected before marking itself as ready! It probably crashed! D:" % [$kind]
      break

    inc numWait

  info "$1 process is now in $2 state, ending wait. It took $3 wait iterations to signal itself as ready." % [$kind, $process.state, $numWait]

proc summonNetworkProcess*(master: MasterProcess, group: uint) =
  info "Summoning network process for group " & $group
  let summoned = summon(Network, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc summonHTMLParser*(master: MasterProcess, group: uint) =
  info "Summoning HTML parser process for group " & $group
  let summoned = summon(Parser, pkHTML, master.server.path).dispatch()
  master.launchAndWait(summoned)

proc parseHTML*(
  master: MasterProcess, group: uint, source: string
): Option[HTMLParseResult] =
  var
    process = master.server.groups[group.int].findProcess(Parser, pkHTML, workers = false)
    numWait: int

  if not *process:
    master.summonNetworkProcess(group)
    return master.parseHTML(group, source)
  
  var prc = &process
  master.waitUntilReady(prc, Parser, pkHTML)

  info (
    "Sending group $1 HTML parser process a request to parse some HTML" % [$group]
  )

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

proc summonCookieWorker*(master: MasterProcess) {.inline.} =
  info "Summoning cookie worker."
  let summoned = summon(CookieWorker, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc summonRendererProcess*(master: MasterProcess) {.inline.} =
  info "Summoning renderer process."
  let summoned = summon(Renderer, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

  # FIXME: investigate why this happens
  var process = &master.server.groups[0].findProcess(Renderer, workers = false)
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
  master.waitUntilReady(prc, Renderer)
  master.server.send(
    (&process).socket,
    RendererRenderDocument(
      document: document
    )
  )

proc setWindowTitle*(master: MasterProcess, title: string) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.setWindowTitle(title)
    return
  
  var prc = &process
  master.waitUntilReady(prc, Renderer)

  master.server.send(
    (&process).socket,
    RendererSetWindowTitle(
      title: title.encode(safe = true)   # So that we can get spaces
    )
  )

#proc cacheCookie*(master: MasterProcess, cookie: ParsedCookie)

proc dispatchRender*(master: MasterProcess, list: IPCDisplayList) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.dispatchRender(list)
    return
  
  var prc = &process
  master.waitUntilReady(prc, Renderer)

  master.server.send(
    (&process).socket,
    RendererMutationPacket(
      list: list
    )
  )

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
  master.waitUntilReady(prc, Renderer) 

  info ("Sending renderer process a font to load: $1 as \"$2\"" % [file, name])
  let encoded = encode( # encode the data in base64 to ensure that it doesn't mess up the JSON packet
    readFile file,
    safe = true
  )
  master.server.send(
    (&process).socket, 
    RendererLoadFontPacket(
       name: "Default",
       content: encoded,
       format: ext[1 ..< ext.len]
    )
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

  while res.isNone:
    #info "Waiting for network process to send a `NetworkFetchResult` x" & $numRecv
    let packet = master.server.receive((&process).socket, NetworkFetchResult)

    if not *packet:
      inc numRecv
      continue

    if *(&packet).response:
      res = packet
      break

    inc numRecv

  res

proc newMasterProcess*(): MasterProcess {.inline.} =
  MasterProcess(server: newIPCServer())
