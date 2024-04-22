import std/[logging, osproc, strutils, options]
import ferus_ipc/server/prelude
import jsony
import ./summon

# Process specific imports

# Network
import sanchar/parse/url
import sanchar/proto/http/shared

import pretty
import ../network/ipc

when defined(unix):
  import std/posix

type
  MasterProcess* = ref object
    server*: IPCServer

proc initialize*(master: MasterProcess) {.inline.} =
  master.server.add(FerusGroup())
  master.server.initialize()

proc poll*(master: MasterProcess) {.inline.} =
  master.server.poll()

proc summonNetworkProcess*(master: MasterProcess, group: uint) =
  info "Summoning network process for group " & $group
  let summoned = summon(Network, ipcPath = master.server.path).dispatch()

  when defined(unix):
    let 
      original = getpid()
      forked = fork()
    
    if forked == 0:
      info "Running: " & summoned
      let (output, res) = execCmdEx(summoned)
      quit(res)
    elif forked < 0:
      error "Fork syscall failed!!!"
      quit(1)
    else:
      master.server.acceptNewConnection()

proc fetchNetworkResource*(
  master: MasterProcess, 
  group: uint, 
  url: URL
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
  
  info ("Sending group $1 network process a request to fetch data from $2" % [$group, $url])
  master.server.send(
    (&process).socket,
    NetworkFetchPacket(url: url)
  )

  info ("Waiting for response from group $1 network process" % [$group])
  
  var
    numRecv: int
    res: Option[NetworkFetchResult]
  
  while res.isNone:
    info "Waiting for network process to send a `NetworkFetchResult` x" & $numRecv
    let packet = master.server.receive(
      (&process).socket,
      NetworkFetchResult
    )
    
    if not *packet:
      inc numRecv
      continue

    if *(&packet).response:
      res = packet
      break

    inc numRecv

  res
    
proc newMasterProcess*: MasterProcess {.inline.} =
  MasterProcess(
    server: newIPCServer()
  )
