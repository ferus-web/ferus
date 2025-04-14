import std/[logging, tables]
import bali/runtime/prelude, bali/internal/sugar
import ../../components/build_utils
import ../../components/ipc/client/prelude
import ../../components/renderer/ipc
import pretty

type
  JSNavigator* = object
    appCodeName*: string
    appName*: string
    appVersion*: string
    buildId*: string
    oscpu*: string

  JSWindow* = object

proc generateIR*(runtime: Runtime, ipc: var IPCClient) =
  debug "components/web/window: generating interfaces"
  runtime.registerType("navigator", JSNavigator)
  runtime.setProperty(JSNavigator, "appCodeName", str("Mozilla"))
  runtime.setProperty(JSNavigator, "appName", str("Netscape"))
  runtime.setProperty(JSNavigator, "appVersion", str("5.0 (X11)"))
  runtime.setProperty(JSNavigator, "buildId", str("20181001000000"))
  runtime.setProperty(
    JSNavigator, "oscpu", str(hostOS & ' ' & getArchitectureUAString())
  )

  var pIpc = addr(ipc)
  runtime.registerType("window", JSWindow)
  runtime.defineFn(
    JSWindow,
    "open",
    proc() =
      let url = runtime.ToString(&runtime.argument(1, required = true))
      pIpc[].send(RendererGotoURL(url: url)),
  )
