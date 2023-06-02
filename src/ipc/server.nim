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

#[
  Instantiate a new client object -- this isn't a real client, just a representation
  of what the server sees!
]#
proc newClient*(connection: Connection, 
                pid: int, 
                affinitySignature: string, 
                role: ProcessType): Client {.inline.} =
  Client(connection: connection, pid: pid, affinitySignature: affinitySignature)

#[
  Add a new "onMessage" event receiver
]#
proc addReceiver*(ipcServer: IPCServer, receiver: Receiver) {.inline.} =
  ipcServer.receivers.add(receiver)

#[
  Try to find a client on the basis of its affinity signature, and process role
]#
proc getClient*(ipcServer: IPCServer, 
                affinitySignature: string, 
                role: ProcessType): Client {.inline.} =
  for affinity, clients in ipcServer.clients:
    if affinity == affinitySignature:
      for cRole, client in clients:
        if cRole == role:
          return client

  raise newException(ValueError, "No such client in affinity signature " & affinitySignature & " with role " & $role)

#[
  Send some JSON data to a connected and registered client
]#
proc send*[T](ipcServer: IPCServer, affinitySignature: string, 
              role: ProcessType, data: T) {.inline.} =
  when defined(ferusUseVerboseLogging):
    info "[src/ipc/server.nim] Sending packet", affSign = affinitySignature, role = $role 
  ipcServer.reactor.send(
    getClient(
      affinitySignature, role
    ).connection,
    jsony.toJson(data)
  )

#[
  Send some JSON data to an explicitly specified UDP connection, 
  this should only be used during the handshake procedure.
]#
proc sendExplicit*[T](ipcServer: IPCServer, conn: Connection, data: T) {.inline.} =
  when defined(ferusUseVerboseLogging):
    info "[src/ipc/server.nim] Sending packet to explicit connection", address=$conn.address
  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(conn, dataConv)

#[
  Parse some data from a string into a JsonNode

  TODO(xTrayambak): deprecate this, it's not a needed function and adds extra overhead
]#
proc parse*(ipcServer: IPCServer, message: string): JsonNode {.inline.} =
  jsony.fromJson(message)

#[
  Check if a particular address is connected and registered
]#
proc isConnected*(ipcServer: IPCServer, address: Address): bool {.inline.} =
  # TODO(xTrayambak) parallelize this searching, it will provide huge boosts for 
  # processMessages()
  for affinity, clients in ipcServer.clients:
    for clientRole, client in clients:
      if client.connection.address.port.int == address.port.int:
        return true

  return false

#[
  Get a client by their address
]#
proc getClientByAddr*(ipcServer: IPCServer, address: Address): Client {.inline.} =
  # TODO(xTrayambak): same as above
  for affinity, clients in ipcServer.clients:
    for clientRole, client in clients:
      if client.connection.address.port.int == address.port.int:
        return client

  raise newException(ValueError, "getClientByAddr() failed")

#[
  Process all messages in the netty queue
]#
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
 
    let client = ipcServer.getClientByAddr(message.conn.address)
    for receivers in ipcServer.receivers:
      receivers(client, data)

#[
  Tick the netty reactor and process all new messages
]#
proc heartbeat*(ipcServer: IPCServer) {.inline.} =
  ipcServer.reactor.tick()
  ipcServer.processMessages()

#[
  Kill the IPC server
]#
proc kill*(ipcServer: IPCServer) {.inline.} =
  info "[src/ipc/server.nim] IPC server is now shutting down"
  ipcServer.alive = false

#[
  Create a reactor, except this will recursively try to find an 
  unoccupied socket in case the default one is occupied.
]#
proc createReactor(port: int = IPC_SERVER_DEFAULT_PORT): tuple[
  reactor: Reactor, 
  port: int] {.inline.} =
  # TODO(xTrayambak) try to parallelize this but it isn't necessary, no visible speedups will occur
  if port > 65536:
    fatal "[src/ipc/server.nim] Maximum port limit reached -- Ferus cannot instantiate. (all ports from 8080 to 65536 are occupied)"
    quit 1

  var res: tuple[reactor: Reactor, port: int]
  try:
    res = (reactor: newReactor("localhost", port), port: port)
  except Exception:
    info "[src/ipc/server.nim] Port is occupied, trying another port!", port=port
    res = createReactor(port + 1)

  return res

#[
  Create a new IPC server
]#
proc newIPCServer*: IPCServer {.inline.} =
  info "[src/ipc/server.nim] IPC server is now binding!", port=IPC_SERVER_DEFAULT_PORT
  var res = createReactor()

  IPCServer(reactor: res.reactor, alive: true, port: res.port, 
            clients: newTable[string, newTable[ProcessType, Client]()]())
