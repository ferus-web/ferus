import netty, jsony, chronicles, weave, constants, os
import std/[tables, sequtils]

type IPCClient* = ref object of RootObj
  reactor*: Reactor
  port*: int
  conn*: Connection

  alive*: bool

proc send[T](ipcClient: IPCClient, data: T) =
  var dataConv = jsony.toJson(data)
  ipcClient.reactor.send(ipcClient.conn, dataConv)

proc handshakeBegin*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] Beginning handshake with IPC server"
  ipcClient.reactor.tick()

  ipcClient.send({
    "payload": IPC_CLIENT_HANDSHAKE,
    "clientPid": getCurrentProcessId()
  }.toTable)

proc heartbeat*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client started using Weave multithreading"
  ipcClient.handshakeBegin()
  while ipcClient.alive:
    ipcClient.reactor.tick()


proc internalHeartbeat*(ipcClient: IPCClient) =
  init(Weave)
  spawn ipcClient.heartbeat
  exit(Weave)

proc newIPCClient*: IPCClient =
  var reactor = newReactor()
  var conn = reactor.connect("127.0.0.1", IPC_SERVER_DEFAULT_PORT)

  IPCClient(reactor: reactor, port: IPC_SERVER_DEFAULT_PORT, conn: conn, alive: true)
