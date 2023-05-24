#[
  The IPC Server.

  This code is licensed under the MIT license
]#

import netty, jsony, chronicles, json, constants, os, tables,
       strutils,
       ../sandbox/processtypes

const FERUS_IPC_SERVER_NUMTHREADS {.intdefine.} = 2

type 
  Client* = ref object of RootObj
    connection*: Connection
    pid*: int
    role*: ProcessType
    affinitySignature*: string

  Receiver* = proc(sender: Client, jsonNode: JSONNode)

  IPCServer* = ref object of RootObj
    reactor*: Reactor
    port*: int
    alive*: bool
    receivers*: seq[Receiver]
            # broker affinity         # process type # client reference
    clients*: TableRef[string, TableRef[ProcessType, Client]]

proc newClient*(connection: Connection, 
                pid: int, 
                affinitySignature: string, 
                role: ProcessType): Client =
  Client(connection: connection, pid: pid, affinitySignature: affinitySignature)

proc addReceiver*(ipcServer: IPCServer, receiver: Receiver) =
  ipcServer.receivers.add(receiver)

proc getClient*(ipcServer: IPCServer, affinitySignature: string, role: ProcessType): Client =
  for affinity, clients in ipcServer.clients:
    if affinity == affinitySignature:
      for cRole, client in clients:
        if cRole == role:
          return client

  raise newException(ValueError, "No such client in affinity signature " & affinitySignature & " with role " & $role)

proc send*[T](ipcServer: IPCServer, affinitySignature: string, 
              role: ProcessType, data: T) =
  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(getClient(affinitySignature, role).connection, dataConv)

proc sendExplicit*[T](ipcServer: IPCServer, conn: Connection, data: T) =
  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(conn, dataConv)

proc parse*(ipcServer: IPCServer, message: string): JsonNode =
  jsony.fromJson(message)

proc isConnected*(ipcServer: IPCServer, address: Address): bool =
  for affinity, clients in ipcServer.clients:
    for clientRole, client in clients:
      if client.connection.address.port.int == address.port.int:
        return true

  return false

proc getClientByAddr*(ipcServer: IPCServer, address: Address): Client =
  for affinity, clients in ipcServer.clients:
    for clientRole, client in clients:
      if client.connection.address.port.int == address.port.int:
        return client

  raise newException(ValueError, "getClientByAddr() failed")

proc processMessages*(ipcServer: IPCServer) =
  for message in ipcServer.reactor.messages:
    var data = ipcServer.parse(message.data)

    if not ipcServer.isConnected(message.conn.address):
      info "[src/ipc/server.nim] New potential IPC client connected!", address=message.conn.address
      var 
        role: ProcessType
        brokerAffinitySignature: string

      if "status" in data:
        let status = data["status"]
          .getStr()
          .parseInt()

        if status == IPC_CLIENT_HANDSHAKE:
          info "[src/ipc/server.nim] New IPC client wants to handshake!"
          
          # Process role
          if "role" notin data:
            warn "[src/ipc/server.nim] IPC client attempted to handshake without describing process role"
            ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_EMPTY_ROLE_KEY}.toTable)
            return
          else:
            try:
              role = data["role"]
                .getInt()
                .intToProcessType()

            except ValueError:
              warn "[src/ipc/server.nim] IPC client sent invalid role key"
              ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_INVALID_ROLE_KEY}.toTable)
              return

          # Process broker affinity signature
          if "brokerAffinitySignature" notin data:
            warn "[src/ipc/server.nim] IPC client attempted to handshake without a broker affinity signature"
            ipcServer.sendExplicit(message.conn, {"handshakeResult": IPC_SERVER_HANDSHAKE_FAILED_NO_BROKER_AFFINITY}.toTable)
            return
          else:
            brokerAffinitySignature = data["brokerAffinitySignature"].getStr()

          ipcServer.sendExplicit(message.conn, {
            "status": IPC_SERVER_HANDSHAKE_ACCEPTED.intToStr(),
            "serverPid": getCurrentProcessId().intToStr()
          }.toTable)

          ipcServer.clients[brokerAffinitySignature] = newTable[ProcessType, Client]()
          ipcServer.clients[brokerAffinitySignature][role] = newClient(
            message.conn, 
            data["clientPid"].getStr().parseInt(), 
            brokerAffinitySignature,
            role
          )
          info "[src/ipc/server.nim] IPC client registered!", clientPid = data["clientPid"].getStr().parseInt()
    else:
      if "status" in data:
        let status = data["status"]
          .getStr()
          .parseInt()
        
        # trying to access data without a registration.
        if status != IPC_CLIENT_HANDSHAKE:
          warn "[src/ipc/server.nim] Something attempted to connect without proper registration -- possibly a misconfigured fuzzer or a goofy little program trying to use this port for something completely different!"
          ipcServer.sendExplicit(message.conn, {
            "status": IPC_SERVER_REQUEST_DECLINE_NOT_REGISTERED.intToStr()
          }.toTable)

    for receivers in ipcServer.receivers:
      receivers(ipcServer.getClientByAddr(message.conn.address), data)
        
proc heartbeat*(ipcServer: IPCServer) =
  ipcServer.reactor.tick()
  ipcServer.processMessages()
 
proc kill*(ipcServer: IPCServer) =
  info "[src/ipc/server.nim] IPC server is now shutting down"
  ipcServer.alive = false

proc newIPCServer*: IPCServer =
  info "[src/ipc/server.nim] IPC server is now binding!", port=IPC_SERVER_DEFAULT_PORT
  var reactor: Reactor
  try:
    reactor = newReactor("localhost", IPC_SERVER_DEFAULT_PORT)
  except Exception:
    fatal "[src/ipc/server.nim] Cannot create IPC server -- port is occupied."
    fatal "[src/ipc/server.nim] Dynamic port selection will be added in the future." # TODO(xTrayambak) I should probably fix this. Seems a bit stupid.
    quit 1

  IPCServer(reactor: reactor, alive: true, port: IPC_SERVER_DEFAULT_PORT, 
            clients: newTable[string, newTable[ProcessType, Client]()]())
