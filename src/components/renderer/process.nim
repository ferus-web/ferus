import std/[options, json, logging, base64, importutils, logging]
import ferus_ipc/client/prelude, jsony
import ferusgfx/[displaylist, fontmgr, textnode, imagenode, gifnode]
import pixie
when defined(linux):
  import ../../components/sandbox/linux

import ../../components/renderer/[core] 
import ../../components/renderer/ipc except newDisplayList

{.passL: "-lwayland-client -lwayland-cursor -lwayland-egl -lxkbcommon -lGL".}

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

  var
    typeface: Option[Typeface]
    font: Option[Font]

  try:
    typeface = some decode(data).readTypeface(packet.format)
  except PixieError as exc:
    error "Failed to load typeface: " & exc.msg & ": fmt=" & packet.format
    return

  try:
    font = newFont(
      &typeface
    ).some()
  except PixieError as exc:
    error "Failed to load font: " & exc.msg & ": fmt=" & packet.format 
    return
  
  if *font:
    renderer.scene.fontManager.setTypeface(name, &typeface)
    renderer.scene.fontManager.set(name, &font)
    info "Loaded font \"" & name & "\" successfully!"

proc mutateTree*(
  client: var IPCClient,
  renderer: FerusRenderer,
  packet: Option[RendererMutationPacket]
) {.inline.} =
  if not *packet:
    warn "Failed to mutate scene tree: cannot reinterpret data as `RendererMutationPacket`!"
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

  info "Committing display list."
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
    warn "Did not get any valid JSON data."
    warn data
    return

  let kind = (&jdata)
    .getOrDefault("kind")
    .getStr()
    .magicFromStr()

  if not *kind:
    warn "No `kind` field inside JSON data provided."
    return

  case &kind
  of feRendererMutation:
    info data
    client.setState(Processing)
    mutateTree(client, renderer, tryParseJson(data, RendererMutationPacket))
    client.setState(Idling)
  of feRendererLoadFont:
    client.setState(Processing)
    loadFont(client, renderer, tryParseJson(data, RendererLoadFontPacket))
    client.setState(Idling)
  of feRendererSetWindowTitle:
    let reinterpreted = tryParseJson(data, RendererSetWindowTitle)
    if not *reinterpreted:
      warn "Cannot reinterpret JSON data as `RendererSetWindowTitle` packet!"
      return
    
    client.setState(Processing)
    renderer.setWindowTitle((&reinterpreted).title.decode())
    client.setState(Idling)
  of feRendererRenderDocument:
    let reinterpreted = tryParseJson(data, RendererRenderDocument)
    if not *reinterpreted:
      warn "Cannot reinterpret JSON data as `RendererRenderDocument` packet!"
      return
    
    client.setState(Processing)
    renderer.renderDocument((&reinterpreted).document)
    client.setState(Idling)
  else:
    discard

proc renderProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering renderer process logic."
  client.setState(Processing)

  let renderer = newFerusRenderer(client)
  renderer.initialize()

  info "Initialized renderer - marking ourselves as Idling."
  client.setState(Idling)
  sandbox(Renderer)

  while true:
    tick renderer
    client.talk(renderer, process)

  close renderer
