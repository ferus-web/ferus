import std/[logging, tables]
import bali/runtime/prelude
import ../../components/build_utils
import pretty

type
  JSNavigator* = object
    appCodeName*: string
    appName*: string
    appVersion*: string
    buildId*: string
    oscpu*: string

  JSWindow* = object

proc generateIR*(runtime: Runtime) =
  debug "components/web/window: generating interfaces"
  runtime.registerType("navigator", JSNavigator)
  runtime.setProperty(JSNavigator, "appCodeName", str("Mozilla"))
  runtime.setProperty(JSNavigator, "appName", str("Netscape"))
  runtime.setProperty(JSNavigator, "appVersion", str("5.0 (X11)"))
  runtime.setProperty(JSNavigator, "buildId", str("20181001000000"))
  runtime.setProperty(JSNavigator, "oscpu", hostOS & ' ' & getArchitectureUAString())

  print runtime.types
