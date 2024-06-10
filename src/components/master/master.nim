import std/[os, logging, osproc, strutils, options, base64]
import ferus_ipc/server/prelude
import jsony
import ./summon

# Process specific imports

# Network
import sanchar/parse/url
import sanchar/proto/http/shared

import ../../components/[network/ipc, renderer/ipc]

when defined(unix):
  import std/posix

type MasterProcess* = ref object
  server*: IPCServer

proc initialize*(master: MasterProcess) {.inline.} =
  master.server.add(FerusGroup())
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
      info "Exiting out with process code: " & $res & "; ciao!"
      quit(res)
    elif forked < 0:
      error "Fork syscall failed!!!"
      quit(1)
    else:
      master.server.acceptNewConnection()

proc waitUntilReady*(
  master: MasterProcess, 
  process: var Option[FerusProcess], 
  kind: FerusProcessKind, parserKind: ParserKind = pkCss
) {.inline.} =
  var numWait: int
  while (&process).state == Initialized:
    info ("Waiting for $1 process to signal itself as ready for work #$2" % [$kind, $numWait])
    master.server.poll()
    process = master.server.groups[0].findProcess(kind, parserKind, workers = false)
    inc numWait

proc summonNetworkProcess*(master: MasterProcess, group: uint) =
  info "Summoning network process for group " & $group
  let summoned = summon(Network, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc summonRendererProcess*(master: MasterProcess) {.inline.} =
  info "Summoning renderer process."
  let summoned = summon(Renderer, ipcPath = master.server.path).dispatch()
  master.launchAndWait(summoned)

proc setWindowTitle*(master: MasterProcess, title: string) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.setWindowTitle(title)
    return

  master.waitUntilReady(process, Renderer)

  master.server.send(
    (&process).socket,
    RendererSetWindowTitle(
      title: title.encode(safe = true)   # So that we can get spaces
    )
  )

proc dispatchRender*(master: MasterProcess, list: IPCDisplayList) {.inline.} =
  var process = master.server.groups[0].findProcess(Renderer, workers = false)

  if not *process:
    master.summonRendererProcess()
    master.dispatchRender(list)
    return

  master.waitUntilReady(process, Renderer)

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

  master.waitUntilReady(process, Renderer) 

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
    master: MasterProcess, group: uint, url: URL
): Option[NetworkFetchResult] =
  var
    process = master.server.groups[group.int].findProcess(Network, workers = false)
    numWait: int

  if not *process:
    # process = master.summonNetworkProcess(group)
    master.summonNetworkProcess(group)
    return master.fetchNetworkResource(group, url)

  while (&process).state == Initialized:
    info "Waiting for network process to signal itself as ready for work x" & $numWait
    master.server.poll()
    process = master.server.groups[group.int].findProcess(Network, workers = false)
    inc numWait

  info (
    "Sending group $1 network process a request to fetch data from $2" % [$group, $url]
  )
  master.server.send((&process).socket, NetworkFetchPacket(url: url))

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
