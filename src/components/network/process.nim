import std/[base64, strutils, logging, options, json, net]
import sanchar/[http, proto/http/shared], sanchar/parse/url, ferus_ipc/client/prelude
import pretty

when defined(ferusUseCurl):
  import webby/httpheaders
  import curly

import jsony
import ../../components/shared/[nix, sugar]
import ../../components/network/ipc
import ../../components/build_utils

when defined(ferusUseCurl):
  var curl = newCurly()

func getUAString*(): string {.inline.} =
  "Mozilla/5.0 ($1 $2) Ferus/$3 (Ferus, like Gecko) Ferus/$3 Firefox/129.0" % [
    (
      when defined(linux):
        "X11; Linux"
      elif defined(win32):
        "Windows NT 10; Win32"
      elif defined(win64):
        "Windows NT 10; Win64"
      elif defined(macos):
        "Macintosh"
      elif defined(freebsd):
        "X11; FreeBSD"
      elif defined(openbsd):
        "X11; OpenBSD"
    ),
    getArchitectureUAString(),
    getVersion(),
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

  # info "User agent is set to \"" & ua & '"'
  info "Getting ready to send HTTP/GET request to: " & $url

  when defined(ferusUseCurl):
    var headers: HttpHeaders
    headers["User-Agent"] = ua

    try:
      let response = curl.get($url, headers = headers)

      result = NetworkFetchResult(
        response: some(
          HTTPResponse(
            httpVersion: response.request.verb,
            code: response.code.uint32,
            content: response.body,
            headers: (
              proc(): Headers =
                var headers: Headers
                let baseHeaders = response.headers.toBase()

                for (key, value) in baseHeaders:
                  headers.add(Header(key: key, value: value))

                headers
            )(),
          )
        )
      )
    except CatchableError as exc:
      error "Failed to send HTTP/GET response to: " & $url
      error exc.msg
      result = NetworkFetchResult(response: none(HTTPResponse))
  else:
    var webClient = httpClient(@[header("User-Agent", ua)])

    result = NetworkFetchResult(response: webClient.get((&fetchData).url).some())

  info "Fetched HTTP/GET response from: " & $url

  client.setState(Idling)

proc talk(client: var IPCClient, process: FerusProcess) {.inline.} =
  var count: cint

  discard nix.ioctl(client.socket.getFd().cint, nix.FIONREAD, addr count)

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
  of feNetworkFetch:
    var odata = client.networkFetch(tryParseJson(data, NetworkFetchPacket))

    if !odata.response:
      client.send(odata.move())
      return

    var resp = &odata.response
    resp.content = resp.content.encode()

    odata.response = some(move(resp))

    client.send(odata.move())
  else:
    discard

proc networkProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering network process logic."
  client.setState(Idling)

  while true:
    client.talk(process)
