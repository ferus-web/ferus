#[
  The IPC Server.

  This code is licensed under the MIT license
]#

import netty, jsony, chronicles, json, taskpools, constants, os, tables,
       ../sandbox/processtypes

const FERUS_IPC_SERVER_NUMTHREADS {.intdefine.} = 2

var tp = Taskpool.new(num_threads=FERUS_IPC_SERVER_NUMTHREADS)

type 
  Client* = ref object of RootObj
    connection*: Connection
    pid*: int
    affinitySignature*: string

  Receiver* = proc(jsonNode: JSONNode)

  IPCServer* = ref object of RootObj
    reactor*: Reactor
    port*: int
    alive*: bool
    receivers*: seq[Receiver]

    clients*: TableRef[ProcessType, Client]

proc newClient*(connection: Connection, pid: int, affinitySignature: string): Client =
  Client(connection: connection, pid: pid, affinitySignature: affinitySignature)

proc addReceiver*(ipcServer: IPCServer, receiver: Receiver) =
  ipcServer.receivers.add(receiver)

proc send*[T](ipcServer: IPCServer, clientId: int, data: T) =
  if clientId > ipcServer.clients.len:
    error "[src/ipc/server.nim] Invalid call to send(); clientId exceeds ipcServer.clients.len! (sanity check failed)", clientId=clientId
    return
    
  if clientId < 0:
    error "[src/ipc/server.nim] Invalid call to send(); clientId is lesser than 0! (sanity check failed)"
    return

  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(ipcServer.clients[clientId], dataConv)

proc sendExplicit*[T](ipcServer: IPCServer, conn: Connection, data: T) =
  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(conn, dataConv)

proc parse*(ipcServer: IPCServer, message: string): JsonNode =
  jsony.fromJson(message)

proc isConnected*(ipcServer: IPCServer, address: Address): bool =
  for pType, client in ipcServer.clients:
    if client.connection.address.port.int == address.port.int:
      return true

  return false

proc processMessages*(ipcServer: IPCServer) =
  for message in ipcServer.reactor.messages:
    var data = ipcServer.parse(message.data)
    for receivers in ipcServer.receivers:
      receivers(data)

    if not ipcServer.isConnected(message.conn.address):
      info "[src/ipc/server.nim] New potential IPC client connected!", address=message.conn.address
      var 
        role: ProcessType
        brokerAffinitySignature: string

      if "status" in data:
        if data["status"].getInt() == IPC_CLIENT_HANDSHAKE:
          info "[src/ipc/server.nim] New IPC client wants to handshake!"
          if "payload" notin data:
            warn "[src/ipc/server.nim] IPC client attempted to handshake without payload key"
            ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_EMPTY_PAYLOAD}.toTable)
            return
          else:
            var payload = data["payload"]
            if "role" notin payload:
              warn "[src/ipc/server.nim] IPC client attempted to handshake without describing process role"
              ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_EMPTY_ROLE_KEY}.toTable)
              return
            else:

              try:
                role = stringToProcessType(payload["role"].getStr())
              except ValueError:
                warn "[src/ipc/server.nim] IPC client sent invalid role key"
                ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_INVALID_ROLE_KEY}.toTable)
                return
          if "brokerAffinitySignature" notin data:
            warn "[src/ipc/server.nim] IPC client attempted to handshake without a broker affinity signature"
            ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_NO_BROKER_AFFINITY}.toTable)
            return
          else:
            brokerAffinitySignature = data["brokerAffinitySignature"].getStr()

          ipcServer.sendExplicit(message.conn, {
            "status": IPC_SERVER_HANDSHAKE_ACCEPTED,
            "serverPid": getCurrentProcessId()
          }.toTable)
          ipcServer.clients[role] = newClient(message.conn, data["clientPid"].getInt(), brokerAffinitySignature)
          info "[src/ipc/server.nim] IPC client registered!", clientPid = data["clientPid"].getInt()

proc internalHeartbeat*(tp: Taskpool, ipcServer: IPCServer) =
  info "[src/ipc/server.nim] internalHeartbeat(): running in multithreaded mode via Weave."
  while ipcServer.alive:
    sleep(8)
    ipcServer.reactor.tick()
    ipcServer.processMessages()
 
proc heartbeat*(ipcServer: IPCServer) =
  internalHeartbeat(tp, ipcServer)

proc kill*(ipcServer: IPCServer) =
  info "[src/ipc/server.nim] IPC server is now shutting down"
  ipcServer.alive = false

proc newIPCServer*: IPCServer =
  info "[src/ipc/server.nim] IPC server is now binding!", port=IPC_SERVER_DEFAULT_PORT
  var reactor = newReactor("localhost", IPC_SERVER_DEFAULT_PORT)
  IPCServer(reactor: reactor, alive: true, port: IPC_SERVER_DEFAULT_PORT, clients: newTable[ProcessType, Client]())
