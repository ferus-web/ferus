## WebSocket logic
## This currently uses the Whisky library, but there are plans to use a homegrown implementation sooner or later.
import std/[importutils, net]
import pkg/[jsony, whisky, shakar]
import ../ipc/client/prelude
import ../js/ipc
import ./[types, ipc]

privateAccess(WebSocket)

var FIONREAD {.importc, header: "<sys/ioctl.h>".}: cint
proc ioctl(fd: cint, op: cint, argp: pointer): cint {.importc, header: "<sys/ioctl.h>".}

proc hasIncoming*(conn: WebSocketConnection): bool {.inline.} =
  var tmp: cint
  discard ioctl(conn.handle.socket.getFd().cint, FIONREAD, tmp.addr)

  tmp > 0

proc tickAllConnections*(client: FerusNetworkClient) =
  ## Tick all WebSocket connections to see if they have any incoming data.

  # TODO: Move this away from `select()` to `epoll()`
  for websocket in client.websockets:
    if websocket.hasIncoming:
      let wsPayload = websocket.handle.receiveMessage()
      failCond *wsPayload

      let payload = &wsPayload
      if payload.kind in {Ping, Pong}:
        # Ignore ping/pong frames. For now.
        continue

      client.ipc.send(
        JSWebSocketEvent(event: JSWebSocketEventType.OnMessage, payload: payload.data)
      )
