## JavaScript interface for WebSocket API.

import std/[logging]
import ../ipc/shared, ../ipc/client/prelude
import ../js/ipc
import pkg/bali/runtime/prelude, pkg/sanchar/parse/url, pkg/[shakar, jsony]

type JSWebSocket* = object
  onopen*: JSValue

proc generateBindings*(runtime: Runtime, client: var IPCClient) =
  var pClient = client.addr
  runtime.registerType("WebSocket", JSWebSocket)
  runtime.defineConstructor(
    "WebSocket",
    proc() =
      failCond pClient != nil

      let address = runtime.ToString(&runtime.argument(1))
      pClient[].send(JSCreateWebSocket(address: parse(address)))
        # Ask the master to ask the network process to create a WS connection.
    ,
  )
