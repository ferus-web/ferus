import netty, jsony, chronicles
import std/[tables, sequtils]

type IPCClient* = ref object of RootObj
  reactor*: Reactor
  port*: int
  conn*: Connection

proc send[T](ipcClient: IPCClient, data: T) =
  var dataConv = jsony.toJson(data)
  ipcClient.reactor.send(ipcClient.conn, dataConv)

proc tick*(ipcClient: IPCClient):
  ipcClient.reactor.tick()

proc newIPCClient*: IPCClient =
  IPCClient()
