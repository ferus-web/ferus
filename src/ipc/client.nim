#[
  The IPC Client.

  This code is licensed under the MIT license
]#

import netty, jsony, chronicles, weave, constants, os, ../sandbox/processtypes
import std/[tables, json]

const FERUS_IPC_CLIENT_NUMTHREADS {.intdefine.} = 2

type
  Receiver* = proc(jsonNode: JSONNode)

  IPCClient* = ref object of RootObj
    reactor*: Reactor
    port*: int
    conn*: Connection
    receivers*: seq[Receiver]

    handshakeCompleted*: bool
    alive*: bool

proc send[T](ipcClient: IPCClient, data: T) =
  var dataConv = jsony.toJson(data)
  ipcClient.reactor.send(ipcClient.conn, dataConv)

proc handshakeBegin*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] Beginning handshake with IPC server"
  ipcClient.reactor.tick()

  ipcClient.send({
    "status": IPC_CLIENT_HANDSHAKE,
    "payload": {
      "role": ptRenderer.int
    }.toTable,
    "clientPid": getCurrentProcessId()
  }.toTable)

proc parse*(ipcClient: IPCClient, message: string): JsonNode =
  jsony.fromJson(message)

proc processMessages*(ipcClient: IPCClient) =
  for msg in ipcClient.reactor.messages:
    var data = ipcClient.parse(msg.data)
    for receiver in ipcClient.receivers:
      receiver(data)

    if "handshakeResult" in data and not ipcClient.handshakeCompleted:
      if data["handshakeResult"].getInt() == IPC_SERVER_HANDSHAKE_ACCEPTED:
        info "[src/ipc/client.nim] We have been accepted by the IPC server!"
      else:
        warn "[src/ipc/client.nim] We have been declined access by the IPC server.", errCode=data["handshakeResult"].getInt()
        quit(1)

proc internalHeartbeat*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client started using Weave multithreading"
  ipcClient.handshakeBegin()
  while ipcClient.alive:
    sleep(8)
    ipcClient.reactor.tick()
    ipcClient.processMessages()

proc heartbeat*(ipcClient: IPCClient) =
  init(Weave)
  ipcClient.internalHeartbeat()
  exit(Weave)

proc kill*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client is now shutting down"
  ipcClient.alive = false

proc newIPCClient*: IPCClient =
  var reactor = newReactor()
  var conn = reactor.connect("127.0.0.1", IPC_SERVER_DEFAULT_PORT)

  IPCClient(reactor: reactor, port: IPC_SERVER_DEFAULT_PORT, conn: conn, alive: true)
