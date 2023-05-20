#[
  Application layer for Ferus.

  This code is licensed under the MIT license
]#

import chronicles, json, netty, tables, strutils
import ipc/[
  server,
  constants
]

import dom/dom
import sandbox/processtypes
import orchestral/server
when defined(linux):
  import sandbox/linux/broker

type FerusApplication* = ref object of RootObj
  orchestral*: OrchestralServer
  dom*: DOM
  broker*: Broker

proc init*(app: FerusApplication) =
  proc getDom(sender: Connection, data: JSONNode) =
    if "result" in data:
      let result = data["result"]

      if result.getInt() == IPC_CLIENT_NEEDS_DOM:
        info "[src/app.nim] Sending DOM to child"
        app.orchestral.server.context.sendExplicit(sender, {
          "result": PACKET_TYPE_DOM.intToStr(),
          "payload": app.dom.serialize()
        }.toTable)

  app.orchestral.server.context.addReceiver(getDom)

proc initRenderer*(app: FerusApplication) =
  app.broker.createNewProcess(ptRenderer)

proc run*(app: FerusApplication) =
  while true:
    app.orchestral.update()

proc newFerusApplication*: FerusApplication =
  info "[src/app.nim] Ferus application layer is now starting"

  var
    iserver = newIPCServer()
    orchestral = newOrchestralServer(iserver)
    broker = newBroker(iserver)

  FerusApplication(orchestral: orchestral, broker: broker)
