import ../../components/ipc/shared
import ../parsers/html/document
import bali/stdlib/console
import pkg/sanchar/parse/url

type
  JSExecPacket* = object
    name*: string
    kind: FerusMagic = feJSExec
    buffer*: string

  JSConsoleMessage* = object
    kind: FerusMagic = feJSConsoleMessage
    message*: string
    level*: ConsoleLevel

  JSTakeDocument* = object
    kind: FerusMagic = feJSTakeDocument
    document*: HTMLDocument

  JSCreateWebSocket* = object
    kind: FerusMagic = feJSCreateWebSocket
    address*: URL

  JSWebSocketEventType* {.pure.} = enum
    OnOpen
    OnMessage
    OnClose

  JSWebSocketEvent* = object
    kind: FerusMagic = feJSWebSocketEvent
    case event*: JSWebSocketEventType
    of OnOpen, OnClose: discard
    of OnMessage:
      payload*: string

export ConsoleLevel
