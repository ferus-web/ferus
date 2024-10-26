import std/[strutils, logging, options, json]
import sanchar/[http, proto/http/shared], sanchar/parse/url, ferus_ipc/client/prelude, jsony
import ../../components/shared/sugar
import ../../components/network/ipc
import ../../components/build_utils

func getUAString*: string {.inline.} =
  "Mozilla/5.0 ($1 $2) Ferus/$3 (Ferus, like Gecko) Ferus/$3 Firefox/129.0" % [
    (
      when defined(linux): 
        "X11; Linux"
      elif defined(win32):
        "Windows 10"
      elif defined(win64):
        "Windows 10"
      elif defined(macos):
        "MacOS"
    ),
    getArchitectureUAString(),
    getVersion()
  ]

proc networkFetch*(
    client: var IPCClient, fetchData: Option[NetworkFetchPacket]
): NetworkFetchResult {.inline.} =
  client.setState(Processing)
  if not *fetchData:
    error "Could not reinterpret JSON data as `NetworkFetchPacket`!"
    return
  
  let 
    url = (&fetchData).url
    ua = getUAString()

  info "User agent is set to \"" & ua & '"'
  info "Getting ready to send HTTP/GET request to: " & $url

  var webClient = httpClient(@[
    header("User-Agent", ua)
  ])

  result = NetworkFetchResult(response: webClient.get((&fetchData).url).some())

  info "Fetched HTTP/GET response from: " & $url

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
    client.talk(process)
