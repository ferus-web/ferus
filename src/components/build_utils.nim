import std/[os, pegs]

proc staticReadVersionFromNimble: string {.compileTime.} =
  ## Stolen from Moe's code :3 

  let
    peg = """@ "version" \s* "=" \s* \" {[0-9.]+} \" @ $""".peg

    nimblePath = currentSourcePath.parentDir() / "../../ferus.nimble"
    nimbleSpec = staticRead(nimblePath)

  var captures: seq[string] = @[""]
  assert nimbleSpec.match(peg, captures)
  assert captures.len == 1
  return captures[0]

proc getVersion*: string {.compileTime.} =
  staticReadVersionFromNimble()

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

proc getCompilerType*: CompilerType =
  when defined(gcc):
    return ctGcc
  
  when defined(msvc):
    return ctMsvc

  when defined(clang):
    return ctClang

  # Generic C compiler
  return ctCc

proc getArchitecture*: string {.inline, compileTime.} =
  hostCPU

proc getHostOS*: string {.inline, compileTime.} =
  hostOS

proc getCompileDate*: string {.inline, compileTime.} =
  CompileDate

proc getBinFormat*: BinFormat {.inline, compileTime.} =
  when defined(win32): return bfWin32
  when defined(win64): return bfWin64
  when defined(mac): return bfMac
  when defined(freebsd) or defined(openbsd) or defined(netbsd) or defined(bsd): return bfBsd
  when defined(linux): return bfLinux

proc isDebugBuild*: bool {.inline, compileTime.} =
  when defined(debug):
    true
  else:
    false

{.warning[UnreachableCode]: on.}
