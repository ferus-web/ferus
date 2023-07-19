{.experimental.}
#[
  The IPC Client.

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#

import netty, jsony, chronicles, constants, os, ../sandbox/processtypes
import std/[tables, json, strutils, threadpool]

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

#[
  Add a new listener for the "onMessage" event
]#
proc addReceiver*(ipcClient: IPCClient, receiver: Receiver) {.inline.} =
  ipcClient.receivers.add(receiver)

#[
  Send some JSON data to a client
]#
proc send*[T](ipcClient: IPCClient, data: T) {.inline.} =
  var dataConv = jsony.toJson(data)
  ipcClient.reactor.send(ipcClient.conn, dataConv)
  when defined(ferusUseVerboseLogging):
    info "[src/ipc/client.nim] Sent packet to server (compile without -d:ferusUseVerboseLogging to disable this)", dataConv=dataConv

#[
  Handshake with the IPC server
]#
proc handshake*(ipcClient: IPCClient) {.inline.} =
  info "[src/ipc/client.nim] Beginning handshake with IPC server"
  ipcClient.reactor.tick()

  ipcClient.send({
    "status": IPC_CLIENT_HANDSHAKE.intToStr(),
    "role": ptRenderer.processTypeToString(),
    "clientPid": getCurrentProcessId().intToStr(),
    "brokerAffinitySignature": ipcClient.brokerSignature
  }.toTable)

#[
  Process one message, processMessages() calls this in a parallelized fashion
]#
proc processMessage*(ipcClient: IPCClient, data: JSONNode) {.gcsafe.} =    
  # Handshake handler
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

  # Other packets
  if "status" in data and ipcClient.handshakeCompleted:
    try:
      let status = data["status"]
                .getStr()
                .parseInt()

      if status == IPC_SERVER_REQUEST_DECLINE_NOT_REGISTERED:
        fatal "[src/ipc/client.nim] We attempted to send a request without first registering! Abort."
        quit(1)
      elif status == IPC_SERVER_REQUEST_TERMINATION:
        fatal "[src/ipc/client.nim] Caught deadly magic number IPC_SERVER_REQUEST_TERMINATION; goodbye!"
        quit(0)

    except ValueError:
      warn "[src/ipc/client.nim] IPC server sent malformed packet (is it a bug?)"

#[
  Process the entire message queue (in parallel by default)  
]#
proc processMessages*(ipcClient: IPCClient) {.inline.} =
  when defined(ferusNoParallelIPC):
    for msg in ipcClient.reactor.messages:
      let data = jsony.fromJson(msg.data)
      for receiver in ipcClient.receivers:
        receiver(data)
      ipcClient.processMessage(data)
  else:
    for msg in ipcClient.reactor.messages:
      let data = jsony.fromJson(msg.data)
      for receiver in ipcClient.receivers:
        receiver(data)

      parallel:
        spawn ipcClient.processMessage(data)

#[
  Tick the netty reactor and process new messages
]#
proc heartbeat*(ipcClient: IPCClient) {.inline.} =
  ipcClient.reactor.tick()
  ipcClient.processMessages()

#[
  Kill the IPC server and inform the server as well
]#
proc kill*(ipcClient: IPCClient, silentDeath: bool = false) {.inline.} =
  info "[src/ipc/client.nim] IPC client is now shutting down"
  if not silentDeath:
    ipcClient.heartbeat()
    ipcClient.send({"result": IPC_CLIENT_SHUTDOWN})
  else:
    warn "[src/ipc/client.nim] We'll die a silent death, without telling the IPC server."
  ipcClient.alive = false

#[
  Create a new IPC client
]#
proc newIPCClient*(brokerSignature: string, port: int): IPCClient {.inline.} =
  var reactor = newReactor()
  var conn = reactor.connect("127.0.0.1", port)

  IPCClient(
    reactor: reactor, port: port, conn: conn, alive: true,
    isBroker: true, brokerSignature: brokerSignature
  )
