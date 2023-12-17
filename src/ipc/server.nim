{.experimental.}

#[
  The IPC Server.

  This code is licensed under the MIT license
]#

import std/[os, json, tables, threadpool], 
      constants,
      chronicles, jsony, netty,
      strutils,
      ../sandbox/processtypes

const FERUS_IPC_SERVER_NUMTHREADS {.intdefine.} = 2

type 
  Client* = ref object of RootObj
    connection*: Connection
    pid*: int
    role*: ProcessType
    affinitySignature*: string

  Receiver* = proc(sender: Client, jsonNode: JSONNode) {.gcsafe.}

  IPCServer* = ref object of RootObj
    reactor*: Reactor
    port*: int
    alive*: bool
    receivers*: seq[Receiver]
    affinityHooks*: seq[tuple[signature: string, fn: proc(client: Client)]]
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
    info "[src/ipc/server.nim] Sending packet (compile without -d:ferusUseVerboseLogging to disable this)", affSign = affinitySignature, role = $role, data = $data
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
    warn "[src/ipc/server.nim] Sending packet to explicit connection (compile without -d:ferusUseVerboseLogging to disable this)", data = $data
  var dataConv = jsony.toJson(data)
  ipcServer.reactor.send(conn, dataConv)

proc onClientWithAffinity*(ipcServer: IPCServer, signature: string, fn: proc(client: Client)) =
  ipcServer.affinityHooks.add((signature: signature, fn: fn))

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
  # processMessages() with lots of tabs/processes
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

proc handleUnknownConn*(ipcServer: IPCServer, message: Message) =
  let data = fromJson(message.data)

  var notifyFn: proc(client: Client)

  var
    role: ProcessType
    brokerAffinitySignature: string

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

      for hook in ipcServer.affinityHooks:
        if hook[0] == brokerAffinitySignature:
          assert notifyFn == nil
          notifyFn = hook[1]

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

    if notifyFn != nil:
      notifyFn(ipcServer.clients[brokerAffinitySignature][role])

    info "[src/ipc/server.nim] IPC client registered!", clientPid = data["clientPid"].getStr().parseInt()

#[
  Process a message
]#
proc processMessage*(ipcServer: IPCServer, message: Message) {.gcsafe.} =
  when defined(ferusUseVerboseLogging):
    info "[src/ipc/server.nim] Got packet from client (compile without -d:ferusUseVerboseLogging to disable this)", dataConv=message.data
  var data = ipcServer.parse(message.data)

  let client = ipcServer.getClientByAddr(message.conn.address)
  for receiver in ipcServer.receivers:
    receiver(client, data)
 
proc processMessages*(ipcServer: IPCServer) {.inline.} =
  var 
    messages = deepCopy ipcServer.reactor.messages
    toDel: seq[int] = @[]
  
  # FIXME: Work, PLEASE JUST WORK. I'M CREATING TWO GOD DAMNED SEQUENCES JUST TO MAKE YOU WORK.
  # PLEASE. WORK.
  for i, msg in messages:
    if not ipcServer.isConnected(msg.conn.address):
      info "[src/ipc/server.nim] New potential IPC client connected!", address=msg.conn.address

      ipcServer.handleUnknownConn(msg)
      toDel.add(i)

  for delete in toDel:
    messages.del(delete)

  when defined(ferusNoParallelIPC):
    # Who knew parallelizing something that depends on itself for data is bad? :P
    for msg in messages:
      let data = jsony.fromJson(msg.data)

      ipcServer.processMessage(msg)
  else:    
    for msg in messages:
      let data = jsony.fromJson(msg.data)

      parallel:
        spawn ipcServer.processMessage(msg)

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
