import std/[base64, options]
import ../../components/shared/[sugar]
import sanchar/parse/url, sanchar/proto/http/shared, ../../components/ipc/shared

type
  NetworkFetchPacket* = object
    kind: FerusMagic = feNetworkFetch
    url*: URL

  NetworkFetchResult* = object
    kind*: FerusMagic = feNetworkSendResult
    response*: Option[HTTPResponse]

  NetworkOpenWebSocket* = object
    kind*: FerusMagic = feNetworkOpenWebSocket
    owner*: string
    address*: URL

  NetworkWebSocketCreationResult* = object
    kind*: FerusMagic = feNetworkWebSocketCreationResult
    error*: Option[string]

func content*(res: NetworkFetchResult): string {.inline.} =
  if !res.response:
    return

  (&res.response).content.decode()
