#[
  Utility for getting information on how Ferus was compiled. Useful for crash reports.

  This code is licensed under the MIT license
]#

const NimblePkgVersion {.strdefine.} = "0.1.0"

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

proc `$`*(ct: CompilerType): string =
  case ct:
    of ctGcc: "GNU Compiler Collection"
    of ctClang: "Clang"
    of ctMsvc: "Microsoft Visual C/C++ Compiler"
    of ctCc: "Generic C Compiler"

proc getVersion*: string = 
  NimblePkgVersion

proc getCompilerType*: CompilerType =
  when defined(gcc):
    return ctGcc
  
  when defined(msvc):
    return ctMsvc

  when defined(clang):
    return ctClang

  # Generic C compiler
  return ctCc

proc getArchitecture*: string =
  hostCPU

proc getHostOS*: string =
  hostOS

proc getCompileDate*: string =
  CompileDate

proc getBinFormat =
  when defined(win32): return bfWin32
  when defined(win64): return bfWin64
  when defined(linux): return bfLinux
  when defined(mac): return bfMac
  when defined(freebsd) or defined(openbsd) or defined(netbsd) or defined(bsd): return bfBsd
  return

proc isDebugBuild*: bool =
  when defined(debug):
    return true

  return false