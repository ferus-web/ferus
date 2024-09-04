import std/[logging, options, json]
import sanchar/[http, proto/http/shared], sanchar/parse/url, ferus_ipc/client/prelude, jsony
import ../../components/network/ipc

proc networkFetch*(
    client: var IPCClient, fetchData: Option[NetworkFetchPacket]
): NetworkFetchResult {.inline.} =
  client.setState(Processing)
  info "Getting ready to send HTTP request."

  if not *fetchData:
    error "Could not reinterpret JSON data as `NetworkFetchPacket`!"
    return

  var webClient = httpClient(@[
    header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0")  
  ])

  result = NetworkFetchResult(response: webClient.get((&fetchData).url).some())

  client.setState(Idling)

proc talk(client: var IPCClient, process: FerusProcess) {.inline.} =
  let
    data = client.receive()
    jdata = tryParseJson(data, JsonNode)

  if not *jdata:
    warn "Did not get any valid JSON data."
    return

  let kind = (&jdata).getOrDefault("kind").getStr().magicFromStr()

  if not *kind:
    warn "No `kind` field inside JSON data provided."
    return

  case &kind
  of feNetworkFetch:
    let data = client.networkFetch(tryParseJson(data, NetworkFetchPacket))
    client.send(data)
  else:
    discard

proc networkProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering network process logic."
  client.setState(Idling)

  while true:
    poll client
    client.talk(process)
