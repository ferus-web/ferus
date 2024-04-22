import std/[options, json]
import sanchar/http, sanchar/parse/url, ferus_ipc/client/prelude,
       jsony
import ../../components/network/ipc

proc networkFetch*(
  client: var IPCClient, 
  fetchData: Option[NetworkFetchPacket]
): NetworkFetchResult {.inline.} =
  client.setState(Processing)
  if not *fetchData:
    client.error "Could not reinterpret JSON data as `NetworkFetchPacket`!"
    return

  var webClient = httpClient()

  result = NetworkFetchResult(
    response: webClient
      .get((&fetchData).url)
      .some()
  )

  client.setState(Idling)

proc talk(client: var IPCClient, process: FerusProcess) {.inline.} =
  let 
    data = client.receive()
    jdata = tryParseJson(data, JsonNode)

  if not *jdata:
    client.warn "Did not get any valid JSON data."
    return
  
  let
    kind = (&jdata)
      .getOrDefault("kind")
      .getStr()
      .magicFromStr()

  if not *kind:
    client.warn "No `kind` field inside JSON data provided."
    return
  
  client.info "Kind: " & $(&kind)
  case &kind
  of feNetworkFetch:
    let data = client.networkFetch(
      tryParseJson(data, NetworkFetchPacket)
    )
    client.send(data)
  else: discard

proc networkProcessLogic*(
  client: var IPCClient, 
  process: FerusProcess
) {.inline.} =
  client.info("Entering network process logic.")
  client.setState(Idling)

  while true:
    poll client
    client.talk(process)
