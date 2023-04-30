#[
  The IPC Client.

  This code is licensed under the MIT license
]#

import netty, jsony, chronicles, taskpools, constants, os
import std/[tables, sequtils]

var tp = Taskpool.new(num_threads=8)

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
    "status": IPC_CLIENT_HANDSHAKE,
    "clientPid": getCurrentProcessId()
  }.toTable)

proc internalHeartbeat*(tp: Taskpool, ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client started using Weave multithreading"
  ipcClient.handshakeBegin()
  while ipcClient.alive:
    sleep(8)
    ipcClient.reactor.tick()

proc heartbeat*(ipcClient: IPCClient) =
  internalHeartbeat(tp, ipcClient)

proc kill*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client is now shutting down"
  ipcClient.alive = false

proc newIPCClient*: IPCClient =
  var reactor = newReactor()
  var conn = reactor.connect("127.0.0.1", IPC_SERVER_DEFAULT_PORT)

  IPCClient(reactor: reactor, port: IPC_SERVER_DEFAULT_PORT, conn: conn, alive: true)
