#[
  The IPC Client.

  This code is licensed under the MIT license
]#

import netty, jsony, chronicles, constants, os, ../sandbox/processtypes
import std/[tables, json, strutils]

type
  Receiver* = proc(jsonNode: JSONNode)

  IPCClient* = ref object of RootObj
    reactor*: Reactor
    port*: int
    conn*: Connection
    receivers*: seq[Receiver]
    
    isBroker*: bool
    brokerSignature*: string

    handshakeCompleted*: bool
    alive*: bool

proc addReceiver*(ipcClient: IPCClient, receiver: Receiver) =
  ipcClient.receivers.add(receiver)

proc send*[T](ipcClient: IPCClient, data: T) =
  var dataConv = jsony.toJson(data)
  ipcClient.reactor.send(ipcClient.conn, dataConv)

proc handshakeBegin*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] Beginning handshake with IPC server"
  ipcClient.reactor.tick()

  ipcClient.send({
    "status": IPC_CLIENT_HANDSHAKE.intToStr(),
    "role": ptRenderer.processTypeToString(),
    "clientPid": getCurrentProcessId().intToStr(),
    "brokerAffinitySignature": ipcClient.brokerSignature
  }.toTable)

proc parse*(ipcClient: IPCClient, message: string): JsonNode =
  jsony.fromJson(message)

proc processMessages*(ipcClient: IPCClient) =
  for msg in ipcClient.reactor.messages:
    var data = ipcClient.parse(msg.data)
    for receiver in ipcClient.receivers:
      receiver(data)

    if "status" in data and not ipcClient.handshakeCompleted:
      try:
        let status = data["status"]
                  .getStr()
                  .parseInt()

        if status == IPC_SERVER_HANDSHAKE_ACCEPTED:
          info "[src/ipc/client.nim] We have been accepted by the IPC server!"
          ipcClient.handshakeCompleted = true
        else:
          warn "[src/ipc/client.nim] We have been declined access by the IPC server.", errCode=status
          quit(1)
      except ValueError:
        warn "[src/ipc/client.nim] IPC server sent malformed packet (is it a bug?)"

proc heartbeat*(ipcClient: IPCClient) =
  ipcClient.handshakeBegin()
  ipcClient.reactor.tick()
  ipcClient.processMessages()

proc kill*(ipcClient: IPCClient) =
  info "[src/ipc/client.nim] IPC client is now shutting down"
  ipcClient.alive = false

proc newIPCClient*(brokerSignature: string): IPCClient =
  var reactor = newReactor()
  var conn = reactor.connect("127.0.0.1", IPC_SERVER_DEFAULT_PORT)

  IPCClient(
    reactor: reactor, port: IPC_SERVER_DEFAULT_PORT, conn: conn, alive: true,
    isBroker: true, brokerSignature: brokerSignature
  )
