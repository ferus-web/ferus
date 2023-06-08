#[
  Application layer for Ferus.

  This code is licensed under the MIT license
]#

import chronicles, json, netty, ferushtml, tables, strutils
import ipc/[
  server,
  constants
]

import utils/miscutils
import dom/dom
import sandbox/processtypes
import orchestral/server
when defined(linux):
  import sandbox/linux/broker

type FerusApplication* = ref object of RootObj
  orchestral*: OrchestralServer
  dom*: DOM
  broker*: Broker

proc processMsg*(app: FerusApplication, sender: Client, data: JSONNode) {.inline.} =
  if "result" in data:
    let result = data["result"]

    if result.getInt() == IPC_CLIENT_NEEDS_DOM:
      info "[src/app.nim] Sending DOM to child"
      app.orchestral.server.context.sendExplicit(sender.connection, {
        "result": PACKET_TYPE_DOM.intToStr(),
        "payload": app.dom.serialize()
      }.toTable)
    elif result.getInt() == IPC_CLIENT_SHUTDOWN:
      info "[src/app.nim] A client is shutting down!", affinitySignature=truncate(sender.affinitySignature, 32), role=processTypeToString(sender.role)
      if sender.role == ptRenderer:
        info "[src/app.nim] Since the renderer is shutting down, we have to die too. Adios!"
        quit 0

proc init*(app: FerusApplication) =
  proc get(sender: Client, data: JSONNode) =
    app.processMsg(sender, data)

  let x = """
  <html>
    <head>
      <title>Hi</title>
    </head>
    <body>
      <p1>Hi</p2>
    </body>
  </html>
  """
  
  info "[src/app.nim] Creating DOM! (main process)"
  var htmlParser = newHTMLParser()
  var doc = htmlParser.parseToDocument(x)

  app.dom = newDOM(doc)

  echo app.dom.document.dump()

  app.orchestral.server.context.addReceiver(get)

proc initRenderer*(app: FerusApplication) {.inline.} =
  app.broker.createNewProcess(ptRenderer)

proc run*(app: FerusApplication) {.inline.} =
  while true:
    app.orchestral.update()

proc newFerusApplication*: FerusApplication {.inline.} =
  info "[src/app.nim] Ferus application layer is now starting"

  var
    iserver = newIPCServer()
    orchestral = newOrchestralServer(iserver)
    broker = newBroker(iserver)

  FerusApplication(orchestral: orchestral, broker: broker, dom: nil)
