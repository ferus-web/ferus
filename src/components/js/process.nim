import std/[logging, json, net]
import
  pkg/jsony,
  pkg/simdutf/base64,
  pkg/bali/grammar/prelude,
  pkg/bali/runtime/prelude,
  pkg/bali/stdlib/console
import
  ../../components/shared/[nix, sugar],
  ../../components/ipc/client/prelude,
  ../../components/web/[window],
  ../../components/web/document as jsdoc,
  ../../components/web/websockets as jswebsocket,
  ./ipc
from ../../components/parsers/html/document import HTMLDocument

type JSProcess* = object
  ipc*: IPCClient
  parser*: Parser
  runtime*: Runtime
  running*: bool = true

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

  js.parser = newParser(data.buffer.decode(urlSafe = true))
  js.runtime = newRuntime(data.name.decode(urlSafe = true), js.parser.parse())
  window.generateIR(js.runtime, js.ipc)
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
  of feGoodbye:
    info "js: got goodbye packet, cleaning up."
    # TODO: make it so that we always respond to goodbye(s), even when in an unreachable/expensive VM loop
    # there's two ways to do this:
    # a) either add a way for a hook function to constantly monitor for this packet (bad performance)
    # b) shift the VM to another thread (good performance but harder to work with)
    js.runtime.vm.halt = true
    js.running = false
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

  while js.running:
    js.talk(process)
