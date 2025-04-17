import ../ipc/client/prelude
import pkg/whisky

type
  WebSocketConnection* = object
    owner*: string
    id*: uint32
    handle*: WebSocket

  FerusNetworkClient* = ref object
    ipc*: IPCClient
    websockets*: seq[WebSocketConnection] ## All open WebSocket instances
    running*: bool = true
