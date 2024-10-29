import ferus_ipc/shared
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

export ConsoleLevel
