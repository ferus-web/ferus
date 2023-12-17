#[
 Content fetcher using ferus_sanchar
]#
import ../ipc/server, 
       ferus_sanchar, chronicles

import ../sandbox/processtypes

when defined(linux):
  import ../sandbox/linux/broker

type NetworkFetcher* = ref object of RootObj
  server*: IPCServer
  broker*: Broker

proc get*(netFetch: NetworkFetcher, url: string): SancharResponse =
 info "[src/net/fetch.nim] Spawning network worker!", url=url
 let signature = netFetch.broker.genSignature()
 netFetch.broker.spawnNewWorker(signature, ptNetwork)

 netFetch.server.onClientWithAffinity(
   signature,
   proc(client: Client) =
     info "[src/net/fetch.nim] Network worker got registered!"
 )

proc newNetworkFetcher*(server: IPCServer, broker: Broker): NetworkFetcher =
  NetworkFetcher(server: server, broker: broker)
