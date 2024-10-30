import std/[base64, options, json, logging, monotimes, net]
import ./ipc
import ./document
import ../../web/dom
import ../../shared/[nix, sugar]
import ferus_ipc/client/prelude
import jsony

proc htmlParse*(
  oparsingData: Option[ParseHTMLPacket]
): HTMLParseResult =
  if !oparsingData:
    warn "Cannot reinterpret JSON data as `ParseHTMLPacket`!"
    return

  let parsingData = &oparsingData
  
  info "Parsing HTML with source length: " & $parsingData.source.len & " chars"
  
  let 
    startTime = getMonoTime()
    document = parseHTML(newStringStream(decode(parsingData.source)))
    endTime = getMonoTime()

  info "Parsed HTML in " & $(endTime - startTime)
 
  HTMLParseResult(
    document: some(document.parseHTMLDocument())
  )

proc talk(client: var IPCClient, process: FerusProcess) {.inline.} =
  var count: cint
  discard nix.ioctl(client.socket.getFd().cint, nix.FIONREAD, addr(count))

  if count < 1:
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
  else:
    discard

proc htmlParserProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering HTML parser process logic."
  client.setState(Idling)
  client.poll()

  while true:
    client.talk(process)
