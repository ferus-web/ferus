import std/options
import sanchar/parse/url, sanchar/proto/http/shared, ferus_ipc/shared

type
  NetworkFetchPacket* = ref object
    kind: FerusMagic = feNetworkFetch
    url*: URL

  NetworkFetchResult* = ref object
    kind: FerusMagic = feNetworkSendResult
    response*: Option[HTTPResponse]
