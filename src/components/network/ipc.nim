import std/[base64, options]
import ../../components/shared/[sugar]
import sanchar/parse/url, sanchar/proto/http/shared, ../../components/ipc/shared

type
  NetworkFetchPacket* = ref object
    kind: FerusMagic = feNetworkFetch
    url*: URL

  NetworkFetchResult* = ref object
    kind*: FerusMagic = feNetworkSendResult
    response*: Option[HTTPResponse]

func content*(res: NetworkFetchResult): string {.inline.} =
  if !res.response:
    return

  (&res.response).content.decode()
