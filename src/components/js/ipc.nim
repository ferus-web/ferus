import ../../components/ipc/shared
import ../parsers/html/document
import bali/stdlib/console

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

export ConsoleLevel
