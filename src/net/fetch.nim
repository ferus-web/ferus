#[
 Content fetcher using cURL

 It'd be great to replace this with a native in-house
 Nim solution soon.
]#
import curly, chronicles

type
 NetworkFetcher* = ref object of RootObj
  pool: CurlPool

proc get*(netFetch: NetworkFetcher, url: string): tuple[code: int, body: string] =
 info "[src/net/fetch.nim] cURL pool now fetching resource!", resUrl=url
 try:
  let resp = netFetch.pool.get(url)

  return (code: resp.code, body: resp.body)
 except CatchableError:
  warn "[src/net/fetch.nim] Could not connect to server."
  return (code: -65536, body: "")

proc newNetworkFetcher*: NetworkFetcher =
 NetworkFetcher(
  pool: newCurlPool(1)
 )