import std/[options, json]
import ferusgfx, ferus_ipc/client/prelude, jsony
import ../../components/renderer/core

proc talk(
  client: var IPCClient,
  renderer: FerusRenderer,
  process: FerusProcess
) {.inline.} =
  return
  poll client
  let data = client.receive()
  
  if data.len < 1:
    return

  let jdata = tryParseJson(data, JsonNode)

  if not *jdata:
    client.warn "Did not get any valid JSON data."
    client.warn data
    return

  let
    kind = (&jdata)
      .getOrDefault("kind")
      .getStr()
      .magicFromStr()

  if not *kind:
    client.warn "No `kind` field inside JSON data provided."
  
  case &kind
  of feRendererMutation:
    echo "e"
  else: discard

proc renderProcessLogic*(
  client: var IPCClient,
  process: FerusProcess
) {.inline.} =
  client.info "Entering renderer process logic."
  client.setState(Processing)

  let renderer = newFerusRenderer(client)
  renderer.initialize()

  client.setState(Idling)

  while true:
    tick renderer
    client.talk(renderer, process)

  close renderer
