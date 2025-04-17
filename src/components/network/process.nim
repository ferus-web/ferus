import std/[base64, strutils, sequtils, importutils, logging, options, os, json, net]
import pkg/sanchar/[http, proto/http/shared], pkg/sanchar/parse/url
import pkg/pretty
import pkg/whisky

when defined(ferusUseCurl):
  import pkg/webby/httpheaders
  import pkg/curly

import pkg/jsony
import ../../components/shared/[nix, sugar]
import ../../components/network/[websocket, types, ipc]
import ../../components/build_utils
import ../../components/ipc/client/prelude

privateAccess(WebSocket)

when defined(ferusUseCurl):
  var curl = newCurly()

func getUAString*(): string {.inline.} =
  "Mozilla/5.0 ($1 $2) Ferus/$3 (Ferus, like Gecko) Ferus/$3 Firefox/134.0" % [
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
    client: FerusNetworkClient, fetchData: Option[NetworkFetchPacket]
): NetworkFetchResult {.inline.} =
  client.ipc.setState(Processing)
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

  client.ipc.setState(Idling)

proc talk(client: FerusNetworkClient, process: FerusProcess) {.inline.} =
  var count: cint

  discard nix.ioctl(client.ipc.socket.getFd().cint, nix.FIONREAD, addr count)

  if count < 1:
    sleep(100)
    return

  let
    data = client.ipc.receive()
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
      client.ipc.send(odata.move())
      return

    var resp = &odata.response
    resp.content = resp.content.encode()

    odata.response = some(move(resp))

    client.ipc.send(odata.move())
  of feNetworkOpenWebSocket:
    let openReq = &tryParseJson(data, NetworkOpenWebSocket)
    let numOwnedAlready =
      uint32(client.websockets.filterIt(it.owner == openReq.owner).len)

    if numOwnedAlready >= 1024:
      # Impose an arbitrary limit of 1024 WebSockets per network process.
      # If you need anything beyond that, you're:
      # 1) out of luck
      # and
      # 2) mentally deranged. No, seriously. Go seek help.
      client.ipc.send(
        NetworkWebSocketCreationResult(
          error: some("too many concurrent WebSocket connections")
        )
      )

    var ws: WebSocketConnection
    try:
      ws = WebSocketConnection(
        owner: openReq.owner,
        id: numOwnedAlready + 1'u32,
        handle: newWebSocket($openReq.address),
      )
    except CatchableError as exc:
      error "network: Failed to create WebSocket connection! Whisky returned: " & exc.msg
      client.ipc.send(
        NetworkWebSocketCreationResult(error: some("internal error: " & exc.msg))
      )

    info "network: Created WebSocket connection to address " & $openReq.address &
      " successfully!"
    client.ipc.send(NetworkWebSocketCreationResult(error: none(string)))
  of feGoodbye:
    info "network: received goodbye packet."

    info "network: closing all websockets"
    for ws in client.websockets:
      ws.handle.close()

    info "network: closing cURL handle"
    curl.close()

    client.running = false
  else:
    discard

proc networkProcessLogic*(client: var IPCClient, process: FerusProcess) {.inline.} =
  info "Entering network process logic."
  var client = FerusNetworkClient(ipc: client)
  client.ipc.setState(Idling)

  while client.running:
    client.talk(process)
    client.tickAllConnections()
