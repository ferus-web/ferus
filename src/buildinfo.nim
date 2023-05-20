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

proc getCompilerType*: CompilerType =
  when defined(gcc): ctGcc
  when defined(clang): ctClang
  when defined(msvc): ctMsvc
  when defined(cc): ctCc

proc getBinFormat*: BinFormat =
  when defined(win32): bfWin32
  when defined(win64): bfWin64
  when defined(linux): bfLinux
  when defined(osx): bfMac
  when defined(bsd): bfBsd

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
