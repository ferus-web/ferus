import std/[options, json, base64, importutils]
import ferus_ipc/client/prelude, jsony
import ferusgfx/[displaylist, fontmgr, textnode, imagenode, gifnode]
import pixie, pixie/fontformats/opentype
import ../../components/renderer/[core] 
import ../../components/renderer/ipc except newDisplayList

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
      decode(data).readTypeface(packet.format)
    ).some()
  except PixieError as exc:
    client.error "Failed to load font: " & exc.msg & ": fmt=" & packet.format 
  
  if *font:
    renderer.scene.fontManager.set(name, &font)
    client.info "Loaded font \"" & name & "\" successfully!"

proc mutateTree*(
  client: var IPCClient,
  renderer: FerusRenderer,
  packet: Option[RendererMutationPacket]
) {.inline.} =
  if not *packet:
    client.warn "Failed to mutate scene tree: cannot reinterpret data as `RendererMutationPacket`!"
    return

  let mutation = (&packet).list
  var list = newDisplayList(renderer.scene.addr)
  privateAccess(GDisplayList)

  for adds in mutation.adds:
    case adds.kind
    of TextNode:
      let content = decode adds.content
      list.add(
        newTextNode(
          content, 
          adds.position, 
          renderer.scene.fontManager
        )
      )
    of ImageNode:
      let content = decode adds.imgContent

      list.add(
        newImageNodeFromMemory(
          content,
          adds.position
        )
      )
    of GIFNode:
      let content = decode adds.gifContent

      list.add(
        newGIFNodeFromMemory(
          content,
          adds.position
        )
      )
    else: discard

  client.info "Committing display list."
  commit list
  
proc talk(
    client: var IPCClient, renderer: FerusRenderer, process: FerusProcess
) {.inline.} =
  poll client
  let data = client.receive()

  if data.len < 1:
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
  of feRendererMutation:
    client.info data
    mutateTree(client, renderer, tryParseJson(data, RendererMutationPacket))
  of feRendererLoadFont:
    loadFont(client, renderer, tryParseJson(data, RendererLoadFontPacket))
  of feRendererSetWindowTitle:
    let reinterpreted = tryParseJson(data, RendererSetWindowTitle)
    if not *reinterpreted:
      client.warn "Cannot reinterpret JSON data as `RendererSetWindowTitle` packet!"
    
    renderer.setWindowTitle((&reinterpreted).title.decode())
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
