#[
  Application layer for Ferus.

  This code is licensed under the MIT license
]#

import chronicles, json
import std/[
  tables,
  strutils,
  marshal,
  os
]
import ipc/[
  server,
  constants
]
import utils/miscutils
import dom/[dom]
import html/[dombuilder]
import sandbox/processtypes
import orchestral/server
import sanchar/[parse/url, http]
when defined(linux):
  import sandbox/linux/broker

type FerusApplication* = ref object of RootObj
  orchestral*: OrchestralServer
  dom*: DOM
  httpClient*: HTTPClient
  urlParser*: URLParser
  broker*: Broker

#[ 
  Handles magic number `IPC_CLIENT_NEEDS_DOM`,
  provides the DOM to the renderer/layout process.
]#
proc serveDOM*(app: FerusApplication, sender: Client) {.inline.} =
  info "[src/app.nim] Sending DOM to child"
  app.orchestral.server.context.sendExplicit(sender.connection, {
      "result": PACKET_TYPE_DOM.intToStr(),
      "payload": app.dom.serialize()
    }.toTable
  )

proc handleHTTPError*(app: FerusApplication, code: uint32) =
  case code:
    of 404:
      error "[src/app.nim] Server could not find the requested resource."
    of 418:
      error "[src/app.nim] Unfortunately, the server does not want to brew coffee for us today. Bummer :("
    of 505:
      error "[src/app.nim] HTTP protocol version not supported."
    of 429:
      error "[src/app.nim] We have been rate limited."
    else:
      error "[src/app.nim] An unhandled non-successful error code.", code=code

proc loadURL*(app: FerusApplication, url: string): bool =
  let resp = app.httpClient.get(
    parse(url)
  )

  if resp.code == 200:
    var document = parseHTML(resp.content)
    app.dom = newDOM(document)
  else:
    app.handleHTTPError(resp.code)

  return true

proc handleHTTPCode*(app: FerusApplication, code: int) =
  case code:
    of 404:
      error "[src/app.nim] Server could not find the requested resource."
    of 418:
      error "[src/app.nim] Unfortunately, the server does not want to brew coffee for us today. Bummer :("
    of 505:
      error "[src/app.nim] HTTP protocol version not supported."
    of 429:
      error "[src/app.nim] We have been rate limited."
    else:
      error "[src/app.nim] An unhandled non-successful error code.", code=code

proc loadFile*(app: FerusApplication, file: string) =
  if not fileExists(file):
    warn "[src/app.nim] loadFile() failed: fileExists() returned false"
    app.loadFile("../data/pages/file-not-found.html")
    return

  var document = parseHTML(readFile(file))

  app.dom = newDOM(document)

#[
  Handles magic number `IPC_CLIENT_SHUTDOWN`,
  sent by clients when they die properly (graceful crashes, lifetime ended)
]#
proc handleProcessShutdown*(app: FerusApplication, sender: Client) {.inline.} =
  info "[src/app.nim] A client is shutting down!", affinitySignature=truncate(sender.affinitySignature, 32)
  if sender.role == ptRenderer:
    info "[src/app.nim] Since the renderer is shutting down, we have to die too. Adios!"
    quit 0

#[
  Handles magic number `IPC_CLIENT_RESULT_HTML_PARSE`,
  sent by the HTML parser children when they are parsing in response
  to a `IPC_CLIENT_DO_HTML_PARSE` magic request.
]#
proc handleHTMLParseResult*(app: FerusApplication, sender: Client, data: JSONNode) {.inline.} =
  if sender.role != ptHtmlParser:
    warn "[src/app.nim] A non-HTML parser attempted to send a HTML document to us. Perhaps this process has been taken over, or is just malfunctioning."
    return

  if "payload" in data:
    let payload = data["payload"].getStr()  
    app.dom = newDOM(to[Document](payload))
  else:
    warn "[src/app.nim] handleHTMLParseResult() cannot proceed as no payload was attached!"

#[
  Process all packets sent by child processes.
]#
proc processMsg*(app: FerusApplication, sender: Client, data: JSONNode) {.inline.} =
  if "result" in data:
    let result = data["result"]

    case result.getInt():
      of IPC_CLIENT_NEEDS_DOM: 
        app.serveDOM(sender)
      of IPC_CLIENT_SHUTDOWN:
        app.handleProcessShutdown(sender)
      of IPC_CLIENT_RESULT_HTML_PARSE:
        app.handleHTMLParseResult(sender, data)
      else:
        warn "[src/app.nim] Ignoring unimplemented protocol magic number.", protoNum=result

proc init*(app: FerusApplication) =
  proc get(sender: Client, data: JSONNode) =
    app.processMsg(sender, data)

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

  FerusApplication(
    orchestral: orchestral, 
    broker: broker,
    httpClient: httpClient(),
    urlParser: newURLParser(),
    dom: nil
  )
