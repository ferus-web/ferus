import std/[logging, json, base64, net]
import ../../components/ipc/client/prelude
import bali/grammar/prelude
import bali/runtime/prelude
import bali/stdlib/console
import jsony
import ../../components/shared/[nix, sugar]
import ../../components/web/[window]
import ../../components/web/document as jsdoc
import ../../components/web/websockets as jswebsocket
from ../../components/parsers/html/document import HTMLDocument
import ./ipc

type JSProcess* = object
  ipc*: IPCClient
  parser*: Parser
  runtime*: Runtime

  document*: HTMLDocument

proc initConsoleIPC*(js: var JSProcess) =
  var pJs = addr(js)

  attachConsoleDelegate(
    proc(level: ConsoleLevel, msg: string) =
      pJs[].ipc.send(JSConsoleMessage(message: msg, level: level))
  )

proc jsExecBuffer*(js: var JSProcess, data: string) =
  info "Executing JavaScript buffer"
  js.ipc.setState(Processing)
  let data = &tryParseJson(data, JSExecPacket)

  js.parser = newParser(data.buffer.decode())
  js.runtime = newRuntime(data.name.decode(), js.parser.parse())
  window.generateIR(js.runtime)
  jsdoc.generateIR(js.runtime)
  jswebsocket.generateBindings(js.runtime, js.ipc)
  jsdoc.updateDocumentState(js.runtime, js.document)
  js.runtime.run()

  js.ipc.setState(Idling)

proc talk(js: var JSProcess, process: FerusProcess) =
  var count: cint

  discard nix.ioctl(js.ipc.socket.getFd().cint, nix.FIONREAD, addr count)

  if count < 1:
    return

  let
    data = js.ipc.receive()
    jdata = tryParseJson(data, JsonNode)

  if not *jdata:
    warn "Did not get any valid JSON data."
    warn data
    return

  let kind = (&jdata).getOrDefault("kind").getStr().magicFromStr()

  if not *kind:
    warn "No `kind` field inside JSON data provided."
    return

  case &kind
  of feJSExec:
    jsExecBuffer(js, data)
  of feJSTakeDocument:
    let packet = &tryParseJson(data, JSTakeDocument)

    debug "Got document for this tab - passing it to JS land."
    js.document = packet.document
  else:
    discard

proc jsProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering JavaScript runtime process logic."
  var js = JSProcess(ipc: client)
  client.setState(Idling)
  client.poll()
  initConsoleIPC(js)

  when not defined(release):
    setLogFilter(lvlNone)
  else:
    setLogFilter(lvlNone)

  while true:
    js.talk(process)
