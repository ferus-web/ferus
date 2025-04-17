#!fmt: off
import std/[options]
import pkg/sanchar/parse/url,
       pkg/sanchar/proto/http/shared,
       pkg/simdutf/base64
import ../../components/ipc/shared,
       ../../components/shared/[sugar]
#!fmt: on

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

proc content*(res: NetworkFetchResult): string {.inline.} =
  if !res.response:
    return

  (&res.response).content.decode(urlSafe = true)
