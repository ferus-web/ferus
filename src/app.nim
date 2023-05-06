#[
  Application layer for Ferus.

  This code is licensed under the MIT license
]#

import chronicles
import ipc/server
import tab

import sandbox/processtypes
when defined(linux):
  import sandbox/linux/broker

type FerusApplication* = ref object of RootObj
  ipcServer*: IPCServer
  tabs*: seq[Tab]
  broker*: Broker

proc initRenderer*(app: FerusApplication) =
  app.broker.createNewProcess(ptRenderer)

proc newFerusApplication*: FerusApplication =
  info "[src/app.nim] Ferus application layer is now starting"

  var server = newIPCServer()
  var broker = newBroker(server)

  FerusApplication(ipcServer: server, tabs: @[], broker: broker)
