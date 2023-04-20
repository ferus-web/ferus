import netty, jsony, chronicles
import std/[tables, sequtils]

type IPCClient* = ref object of RootObj
  reactor*: Reactor
  port*: int
  conn*: Connection

proc send[T](ipcClient: IPCClient, data: T) =
  var dataConv = data.toJson


proc newIPCClient* =
  var c = newReactor()
  #var c2s = c.connect("127.0.0.1", 2048)
