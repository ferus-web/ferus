import std/[options, json, base64, importutils]
import ferusgfx, ferus_ipc/client/prelude, jsony
import pixie, pixie/fontformats/opentype
import ../../components/renderer/[core, ipc]

proc readTypeface*(data, format: string): Typeface {.raises: [PixieError].} =
  ## Loads a typeface from data.
  try:
    result =
      case format:
        of "ttf":
          parseTtf(data)
        of "otf":
          parseOtf(data)
        of "svg":
          parseSvgFont(data)
        else:
          raise newException(PixieError, "Unsupported font format")
  except IOError as e:
    raise newException(PixieError, e.msg, e)

  result.filePath = "<in-memory typeface>"

proc loadFont*(
  client: var IPCClient,
  renderer: FerusRenderer,
  loadFontPacket: Option[RendererLoadFontPacket]
) {.inline.} =
  let
    packet = &loadFontPacket
    data = packet.content
    name = packet.name

  var font: Option[Font]

  try:
    font = newFont(
      decode(data).readTypeface("ttf")
    ).some()
  except PixieError as exc:
    client.error "Failed to load font: " & exc.msg
  
  if *font:
    renderer.scene.fontManager.set(name, &font)
    client.info "Loaded font \"" & name & "\" successfully!"

proc talk(
    client: var IPCClient, renderer: FerusRenderer, process: FerusProcess
) {.inline.} =
  poll client
  let data = client.receive()

  if data.len < 1:
    echo "empty"
    return

  let jdata = tryParseJson(data, JsonNode)

  if not *jdata:
    client.warn "Did not get any valid JSON data."
    client.warn data
    return

  let kind = (&jdata)
    .getOrDefault("kind")
    .getStr()
    .magicFromStr()

  if not *kind:
    client.warn "No `kind` field inside JSON data provided."
    return

  case &kind
  of feRendererMutation: discard
  of feRendererLoadFont:
    loadFont(client, renderer, tryParseJson(data, RendererLoadFontPacket))
  else:
    discard

proc renderProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  client.info "Entering renderer process logic."
  client.setState(Processing)

  let renderer = newFerusRenderer(client)
  renderer.initialize()

  client.setState(Idling)

  while true:
    tick renderer
    client.talk(renderer, process)

  close renderer
