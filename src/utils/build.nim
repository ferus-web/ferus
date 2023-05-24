#[
  Utility for getting information on how Ferus was compiled. Useful for crash reports.

  This code is licensed under the MIT license
]#
type
  CompilerType* = enum
    ctGcc
    ctClang
    ctMsvc
    ctCc

  BinFormat* = enum
    bfWin32
    bfWin64
    bfLinux
    bfMac
    bfBsd

proc getVersion*: string =
  "0.1.0"

proc getCompilerType =
  # TODO(xTrayambak) maybe this should be fixed.
  return

proc getBinFormat =
  # TODO(xTrayambak) maybe this one too... ^_^
  return

proc isDebugBuild*: bool =
  when defined(debug):
    true

  false

proc useVerboseLogging*: bool =
  when defined(ferusUseVerboseLogging):
    true

  false

proc isDangerBuild*: bool =
  when defined(danger):
    true

  false
