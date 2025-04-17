import std/[options, json, logging, monotimes, net, os]
import pkg/jsony, pkg/simdutf/base64
import
  ./[document, ipc],
  ../../web/dom,
  ../../shared/[nix, sugar],
  ../../../components/ipc/client/prelude

proc htmlParse*(oparsingData: Option[ParseHTMLPacket]): HTMLParseResult =
  if !oparsingData:
    warn "Cannot reinterpret JSON data as `ParseHTMLPacket`!"
    return

  let parsingData = &oparsingData

  info "Parsing HTML with source length: " & $parsingData.source.len & " chars"

  let
    startTime = getMonoTime()
    document = parseHTML(newStringStream(decode(parsingData.source, urlSafe = true)))
    endTime = getMonoTime()

  info "Parsed HTML in " & $(endTime - startTime)

  HTMLParseResult(document: some(document.parseHTMLDocument()))

type HTMLParserData* = object
  running*: bool = true
  documentsParsed*: uint64

proc talk(
    client: var IPCClient, state: var HTMLParserData, process: FerusProcess
) {.inline.} =
  var count: cint
  discard nix.ioctl(client.socket.getFd().cint, nix.FIONREAD, addr(count))

  if count < 1:
    sleep(250)
    return

  let
    data = client.receive()
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
  of feParserParse:
    client.setState(Processing)
    let data = htmlParse(tryParseJson(data, ParseHTMLPacket))

    client.send(data)
    client.setState(Idling)

    inc state.documentsParsed
  of feGoodbye:
    info "html: got goodbye packet, exiting."
    info "html: we parsed " & $state.documentsParsed &
      " documents throughout this process's lifetime"
    state.running = false
  else:
    discard

proc htmlParserProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering HTML parser process logic."
  var data = HTMLParserData()
  client.setState(Idling)
  client.poll()

  while data.running:
    client.talk(data, process)
