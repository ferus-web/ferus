import std/[logging, tables]
import bali/runtime/prelude
import pretty

type
  JSNavigator* = object
    appCodeName*: string = "Mozilla"
    appName*: string = "Netscape"
    appVersion*: string = "5.0 (X11)"
    buildId*: string = "20181001000000"
    oscpu*: string = "Linux x86_64"

  JSWindow* = object

proc generateIR*(runtime: Runtime) =
  debug "components/web/window: generating interfaces"
  runtime.registerType("navigator", JSNavigator)
  runtime.setProperty(JSNavigator, "appCodeName", str("Mozilla"))
  runtime.setProperty(JSNavigator, "appName", str("Netscape"))
  runtime.setProperty(JSNavigator, "appVersion", str("5.0 (X11)"))
  runtime.setProperty(JSNavigator, "buildId", str("20181001000000"))
  runtime.setProperty(JSNavigator, "oscpu", str("Linux x86_64"))

  print runtime.types
