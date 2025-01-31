import std/[os, net, options, sugar, times, sets], jsony
import ../shared

when not defined(ferusInJail):
  import std/logging

proc `*`[T](opt: Option[T]): bool {.inline, noSideEffect, gcsafe.} =
  # dumb hacks to make code look less yucky
  opt.isSome

proc `&`[T](opt: Option[T]): T {.inline, noSideEffect, gcsafe.} =
  opt.get()

when defined(unix):
  from std/posix import getuid

when defined(ssl):
  import std/openssl

  proc dumpHook*(s: var string, v: SslPtr) =
    discard

  proc dumpHook*(s: var string, v: SslServerGetPskFunc) =
    discard

  proc dumpHook*(s: var string, v: SslClientGetPskFunc) =
    discard

type
  AlreadyRegisteredIdentity* = object of CatchableError
  InitializationFailed* = object of Defect
  IPCClient* = object
    socket*: Socket
    path*: string
    connected: bool = false

    process: Option[FerusProcess]

    onConnect*: proc()
    onError*: proc(error: FailedHandshakeReason)

proc send*[T](client: var IPCClient, data: T) {.inline.} =
  let serialized = (toJson data) & '\0'

  when defined(ferusIpcLogSendsToStdout):
    echo serialized

  # debug "Sending: " & serialized

  client.socket.send(serialized)

proc tryParseJson*[T](data: string, kind: typedesc[T]): Option[T] {.inline.} =
  try:
    data.fromJson(kind).some()
  except CatchableError:
    none T

proc warn*(client: var IPCClient, message: string) {.inline, gcsafe.}

proc receive*(client: var IPCClient): string {.inline, gcsafe.} =
  var buff: string

  while true:
    let c = client.socket.recv(1)

    if c == "":
      break

    case c[0]
    of ' ', '\0', char(10):
      break
    else:
      discard

    buff &= c

  buff

proc receive*[T](
    client: var IPCClient, struct: typedesc[T]
): Option[T] {.inline, gcsafe.} =
  let data = client.receive()

  try:
    data.fromJson(struct).some()
  except JsonError as exc:
    if client.connected:
      client.warn "receive(" & $struct & ") failed: " & exc.msg
      client.warn "buffer: " & data
    else:
      when not defined(ferusInJail):
        client.warn "receive(" & $struct & ") failed: " & exc.msg
        client.warn "buffer: " & data

    none T

proc info*(client: var IPCClient, message: string) {.inline.} =
  client.send(FerusLogPacket(level: 0'u8, message: message))

proc warn*(client: var IPCClient, message: string) {.inline.} =
  client.send(FerusLogPacket(level: 1'u8, message: message))

proc error*(client: var IPCClient, message: string) {.inline.} =
  client.send(FerusLogPacket(level: 2'u8, message: message))

proc debug*(client: var IPCClient, message: string) {.inline, gcsafe.} =
  client.send(FerusLogPacket(level: 3'u8, message: message))

proc handshake*(client: var IPCClient) =
  when not defined(ferusInJail):
    info "IPC client performing handshake."

  client.send(HandshakePacket(process: &client.process))

  let resPacket = &client.receive(HandshakeResultPacket)

  if resPacket.accepted:
    if client.onConnect != nil:
      client.onConnect()
  else:
    if client.onError != nil:
      client.onError(resPacket.reason)

proc requestDataTransfer*(
    client: var IPCClient, reason: DataTransferReason, location: sink DataLocation
): Option[DataTransferResult] =
  client.send(DataTransferRequest(reason: reason, location: location))

  client.receive(DataTransferResult)

proc connect*(
    client: var IPCClient, path: Option[string] = none string
): string {.inline, discardable.} =
  proc inner(client: var IPCClient, num: int = 0): string {.inline.} =
    when not defined(ferusInJail):
      if not existsEnv("XDG_RUNTIME_DIR"):
        raise newException(
          InitializationFailed,
          "XDG_RUNTIME_DIR is not set. The IPC client cannot find any server to connect to.",
        )
    else:
      quit 1

    let path = getEnv("XDG_RUNTIME_DIR") / "ferus-ipc-master-" & $num & ".sock"

    try:
      client.socket.connectUnix(path)
      client.path = path

      path
    except OSError:
      when not defined(ferusInJail):
        if num > 1000:
          raise newException(
            InitializationFailed,
            "Could not find Ferus' master IPC server after 1000 " &
              "tries. Are you sure that a ferus_ipc instance is running?",
          )
      else:
        # we must quietly die otherwise writing to stdout will trigger seccomp!
        if num > 1000:
          quit(1)

      inner(client, num + 1)

  if not *path:
    inner(client)
  else:
    client.socket.connectUnix(&path)
    client.path = &path

    &path

proc identifyAs*(
    client: var IPCClient, process: FerusProcess
) {.inline, raises: [AlreadyRegisteredIdentity].} =
  if *client.process:
    raise newException(
      AlreadyRegisteredIdentity,
      "Already registered as another process. You cannot call `identifyAs` twice!",
    )

  client.process = some(process)

proc setState*(client: var IPCClient, state: FerusProcessState) {.inline.} =
  if not *client.process:
    raise newException(
      ValueError,
      "No process was registered before calling `setState()`. Run `identifyAs()` and provide a process first!",
    )

  var process = &client.process
  process.state = state

  client.process = some(process)

  client.send(ChangeStatePacket(state: state))

proc poll*(client: var IPCClient) =
  discard #[client.send(
    KeepAlivePacket()
  )]#

proc newIPCClient*(): IPCClient {.inline.} =
  IPCClient(socket: newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP))

export shared
