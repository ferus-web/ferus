import std/[os, logging, net, options, sugar, strutils, times, json]

when defined(ssl):
  import std/openssl

proc `*`[T](opt: Option[T]): bool {.inline, noSideEffect, gcsafe.} =
  # dumb hacks to make code look less yucky
  opt.isSome

proc `&`[T](opt: Option[T]): T {.inline, noSideEffect, gcsafe.} =
  opt.get()

import jsony
import ../shared, ./groups

when defined(unix):
  from std/posix import getuid, kill, SIGKILL, unlink

when defined(ssl):
  proc parseHook*(s: string, i: int, v2: SslPtr) =
    discard

  proc parseHook*(s: string, i: int, v2: SslServerGetPskFunc) =
    discard

  proc parseHook*(s: string, i: int, v2: SslClientGetPskFunc) =
    discard

when defined(release):
  const
    FerusIpcUnresponsiveThreshold* = "120".parseFloat
    FerusIpcDeadThreshold* = "240".parseFloat
    FerusIpcKickThreshold* = "400".parseFloat
else:
  when defined(ferusIpcMyTimeIsPrecious):
    const
      FerusIpcUnresponsiveThreshold* = "3".parseFloat
      FerusIpcDeadThreshold* = "5".parseFloat
      FerusIpcKickThreshold* = "7".parseFloat
  else:
    const
      FerusIpcUnresponsiveThreshold* = "30".parseFloat
      FerusIpcDeadThreshold* = "100".parseFloat
      FerusIpcKickThreshold* = "140".parseFloat

type
  BadMessageSeverity* = enum
    Low = 0 # probably user caused error
    Medium = 1 # maybe compromised
    High = 2 # probably compromised

  ProcessIdent* = object
    group*, index*: uint

  InitializationFailed* = object of Defect
  IPCServer* = object
    socket*: Socket
    groups*: seq[FerusGroup]
    path*: string

    onConnection*: proc(process: FerusProcess)
    onDataTransfer*: proc(process: FerusProcess, request: DataTransferRequest)
    handler*: proc(process: FerusProcess, kind: FerusMagic, payload: string)

    receiveFromQueue: seq[ProcessIdent]

    kickQueue: seq[FerusProcess]

proc send*[T](server: var IPCServer, sock: Socket, data: T) {.inline.} =
  let serialized = (toJson data) & '\0'

  when defined(ferusIpcLogSendsToStdout):
    echo serialized

  sock.send(serialized)

proc commitKicks*(server: var IPCServer) {.inline.} =
  for i, process in server.kickQueue:
    info ("Kicking process [group:$1, pid:$2]" % [$process.group, $process.pid])
    server.groups[process.group].processes.del(
      server.groups[process.group].find(process)
    )

    # ensure that the process can no longer talk to us
    close process.socket

  server.kickQueue.reset()

proc kick*(server: var IPCServer, process: FerusProcess) {.inline.} =
  if process notin server.kickQueue:
    server.kickQueue.add(process)
  else:
    warn (
      "kick(): attempted to add process to kick queue twice [group: $1, pid: $2]" %
      [$process.group, $process.pid]
    )

proc reportBadMessage*(
    server: var IPCServer,
    process: FerusProcess,
    error: string,
    severity: BadMessageSeverity,
) {.inline.} =
  info ("PID $1 sent a bad message. Error: $2" % [$process.pid, error])

  case severity
  of Low:
    server.send(process.socket, BadMessagePacket(error: error))
  of Medium:
    server.kick(process)
  of High:
    # kick and kill process
    info (
      "PID $1 sent a potentially maliciously crafted packet. Killing it." %
      [$process.pid]
    )

    when defined(unix):
      let res = kill(process.pid.int32, SIGKILL)

      if res != 0:
        error "Could not kill likely compromised process! Just kicking it for now."
    else:
      warn "Cannot kill process on unsupported platform."

    server.kick(process)

proc receive*(server: IPCServer, socket: Socket): string {.inline.} =
  var buff: string

  while true:
    let c = socket.recv(1)

    if c == "":
      break

    case c[0]
    of '\0', char(10):
      break
    else:
      discard

    buff &= c

  buff

proc receive*[T](
    server: IPCServer, socket: Socket, kind: typedesc[T]
): Option[T] {.inline.} =
  try:
    server.receive(socket).fromJson(kind).some()
  except CatchableError:
    none T

proc findDeadProcesses*(server: var IPCServer) {.noinline.} =
  let epoch = epochTime()
  var dead: seq[FerusProcess]

  for gi, group in server.groups:
    for i, fproc in group:
      var mfproc = group.processes[i]
      let delta = epoch - fproc.lastContact

      if fproc.state != Unreachable and fproc.state != Dead:
        if delta > FerusIpcUnresponsiveThreshold:
          mfproc.state = Unreachable
      else:
        if fproc.state != Dead and delta > FerusIpcDeadThreshold and
            delta < FerusIpcKickThreshold:
          info "Marking process as dead: group=$1, pid=$2, kind=$3, worker=$4" %
            [$fproc.group, $fproc.pid, $fproc.kind, $fproc.worker]
          if fproc.kind == Parser:
            info " ... (parser kind: " & $fproc.pKind & ')'

          mfproc.state = Dead
        elif delta > FerusIpcKickThreshold:
          info "Process has been unresponsive for $1 seconds, it is now considered dead: group=$2, pid=$3, kind=$4, worker=$5" %
            [$delta, $fproc.group, $fproc.pid, $fproc.kind, $fproc.worker]
          dead.add(fproc)

      server.groups[gi][i] = mfproc

  for process in dead:
    server.kick(process)

proc acceptNewConnection*(server: var IPCServer) =
  var
    conn: Socket
    address: string

  server.socket.acceptAddr(conn, address)

  info "New connection from: " & address
  let packet = server.receive(conn, HandshakePacket)

  if not *packet:
    server.send(conn, HandshakeResultPacket(accepted: false, reason: fhInvalidData))
    close conn
    return

  let
    data = &packet
    groupId = data.process.group

  if not data.process.worker:
    for group in server.groups:
      if group.id == groupId and
          *group.find((process: FerusProcess) => process.equate(data.process)):
        server.send(
          conn, HandshakeResultPacket(accepted: false, reason: fhRedundantProcess)
        )
        return

  info "Process is probably not a duplicate, accepting it."
  var process = deepCopy(data.process)
  process.lastContact = epochTime()
  process.socket = conn
  server.groups[groupId].processes.add(process)

  server.send(conn, HandshakeResultPacket(accepted: true))

proc add*(server: var IPCServer, group: FerusGroup): uint64 {.discardable, inline.} =
  var mGroup = deepCopy(group)
  let id = server.groups.len.uint64
  mGroup.id = id
  server.groups.add(mGroup)

  id

proc tryParseJson*[T](data: string, kind: typedesc[T]): Option[T] {.inline.} =
  try:
    data.fromJson(kind).some()
  except CatchableError:
    none T

proc processChangeState(
    server: var IPCServer, process: var FerusProcess, data: ChangeStatePacket
) {.inline.} =
  info "PID $1 wants to change process state from $2 -> $3" %
    [$process.pid, $process.state, $data.state]

  if process.state == Dead:
    server.reportBadMessage(process, "Dead process attempted to change state", High)
    return

  if data.state == Dead or data.state == Unreachable:
    server.reportBadMessage(
      process,
      "Process attempted to mark itself as server-discretion-reserved state: " &
        $data.state,
      High,
    )
    return

  process.state = data.state

proc log(
    server: var IPCServer, process: FerusProcess, opacket: Option[FerusLogPacket]
) {.inline.} =
  if not *opacket:
    server.reportBadMessage(
      process, "No logging data provided (or logging data failed to parse)", Low
    )
    return

  let packet = &opacket

  let message =
    "[group:$1, pid:$2]: $3" % [$process.group, $process.pid, packet.message]

  case packet.level
  of 0:
    info message
  of 1:
    warn message
  of 2:
    error message
  of 3:
    debug message
  else:
    server.reportBadMessage(
      process, "Log packet contains invalid logging level: " & $packet.level, Medium
    )

var FIONREAD {.importc, header: "<sys/ioctl.h>".}: cint
proc ioctl(fd: cint, op: cint, argp: pointer): cint {.importc, header: "<sys/ioctl.h>".}

proc talk(server: var IPCServer, process: var FerusProcess) {.inline.} =
  var count: cint

  discard ioctl(process.socket.getFd().cint, FIONREAD, addr count)

  if count < 1:
    return

  let
    rawData = server.receive(process.socket)
    data = tryParseJson(rawData, JsonNode)

  process.lastContact = epochTime()

  if rawData.len < 1:
    return

  if not *data:
    server.reportBadMessage(process, "Invalid JSON data provided for IPC.", Low)
    return

  let
    jsd = &data
    kind = jsd.getOrDefault("kind").getStr().magicFromStr()

  if not *kind:
    server.reportBadMessage(process, "No `kind` string inside JSON IPC data.", Medium)
    return

  case &kind
  of feLogMessage:
    server.log(process, tryParseJson(rawData, FerusLogPacket))

    # server.send(process.socket, KeepAlivePacket())
  of feChangeState:
    let changePacket = tryParseJson(rawData, ChangeStatePacket)

    if not *changePacket:
      return

    server.processChangeState(process, &changePacket)

    # server.send(process.socket, KeepAlivePacket())
  of feDataTransferRequest:
    let transferRequest = tryParseJson(rawData, DataTransferRequest)

    if not *transferRequest:
      return

    if server.onDataTransfer != nil:
      process.transferring = true
      server.onDataTransfer(process, &transferRequest)
      process.transferring = false
  else:
    if server.handler != nil:
      server.handler(process, &kind, rawData)
    else:
      raise newException(
        ValueError,
        "Unhandled opcode: " & $(&kind) & " and a handler proc was not defined.",
      )

proc receiveMessages*(server: var IPCServer) {.inline.} =
  for gi, group in server.groups:
    validate group
    # debug "receiveMessages(): processing group " & $group.id

    for i, _ in group:
      var process = group[i]
      server.talk(process)
      server.groups[gi][i] = move(process)

  server.commitKicks()

proc poll*(server: var IPCServer) =
  server.findDeadProcesses()
  server.receiveMessages()

proc `=destroy`*(server: IPCServer) =
  info "IPC server is now shutting down; closing socket!"

  if server.path.len > 0:
    discard unlink(server.path.cstring)

    removeFile(server.path)
    server.socket.close()

proc bindServerPath*(server: var IPCServer): string =
  proc bindOptimalPath(socket: Socket, num: int = 0): string =
    if not existsEnv("XDG_RUNTIME_DIR"):
      raise newException(
        InitializationFailed,
        "XDG_RUNTIME_DIR is not set. Ferus cannot start an IPC server!",
      )

    let
      uid = getuid().int
      curr = getEnv("XDG_RUNTIME_DIR") / "ferus-ipc-master-" & $num & ".sock"

    try:
      socket.bindUnix(curr)
      result = curr
      info "Successfully binded to: " & curr
    except OSError:
      debug curr & " is occupied; finding another socket file."
      if num > int16.high:
        raise newException(
          InitializationFailed,
          "Failed to find an optimal server socket path after " & $int16.high &
            "tries. You might have *quite* a few Ferus instances open (or we messed up). " &
            "Try to manually remove any file that follows this pattern: `/tmp/ferus-ipc-master-*.sock`",
        )

      return bindOptimalPath(socket, num + 1)

  when defined(unix):
    return bindOptimalPath(server.socket)

  raise newException(
    InitializationFailed, "Windows/non *NIX systems are not supported yet. Sorry! :("
  )

proc initialize*(server: var IPCServer, path: Option[string] = none string) {.inline.} =
  debug "IPC server initializing"
  # server.socket.setSockOpt(OptReusePort, true)
  if path.isSome:
    server.socket.bindUnix(path.unsafeGet())
    server.path = unsafeGet path
  else:
    server.path = server.bindServerPath()

  server.socket.listen(65536)

proc newIPCServer*(): IPCServer {.inline.} =
  IPCServer(socket: newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP))

export sugar
