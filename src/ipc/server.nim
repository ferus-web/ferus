import netty, jsony, chronicles, json, weave, constants, os, tables

type Client* = ref object of RootObj
  connection*: Connection
  pid*: int

type IPCServer* = ref object of RootObj
  reactor*: Reactor
  port*: int
  alive*: bool

  clients*: seq[Client]

proc newClient*(connection: Connection, pid: int): Client =
  Client(connection: connection, pid: pid)

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
  for client in ipcServer.clients:
    if client.connection.address.port.int == address.port.int:
      return true

  return false

proc processMessages*(ipcServer: IPCServer) =
  for message in ipcServer.reactor.messages:
    var data = ipcServer.parse(message.data)
    if not ipcServer.isConnected(message.conn.address):
      info "[src/ipc/server.nim] New potential IPC client connected!", address=message.conn.address

      if "payload" in data:
        if data["payload"].getInt() == IPC_CLIENT_HANDSHAKE:
          info "[src/ipc/server.nim] New IPC client wants to handshake!"
          ipcServer.sendExplicit(message.conn, {
            "payload": IPC_SERVER_HANDSHAKE_ACCEPTED,
            "serverPid": getCurrentProcessId()
          }.toTable)
          ipcServer.clients.add(newClient(message.conn, data["clientPid"].getInt()))
          info "[src/ipc/server.nim] IPC client registered!", clientPid = data["clientPid"].getInt()


proc internalHeartbeat*(ipcServer: IPCServer) =
  info "[src/ipc/server.nim] internalHeartbeat(): running in multithreaded mode via Weave."
  while ipcServer.alive:
    ipcServer.reactor.tick()
    ipcServer.processMessages()
 
proc heartbeat*(ipcServer: IPCServer) =
  init(Weave)
  spawn ipcServer.internalHeartbeat
  exit(Weave)

proc newIPCServer*: IPCServer =
  info "[src/ipc/server.nim] IPC server is now binding!", port=IPC_SERVER_DEFAULT_PORT
  var reactor = newReactor("localhost", IPC_SERVER_DEFAULT_PORT)
  IPCServer(reactor: reactor, alive: true, port: IPC_SERVER_DEFAULT_PORT, clients: @[])
