import std/os
import ferus_ipc/server/prelude

const
  FerusInstallPath {.strdefine: "".} = "./"

type Summon* = ref object
  process*: FerusProcess
  ipcPath*: string

proc dispatch*(summon: Summon): string {.inline.} =
  var s: string

  when defined(ferusAddMangohudToRendererPrefix):
    if summon.process.kind == Renderer:
      s &= "mangohud --dlsym "

  when defined(ferusSandboxAttachStrace):
    s &= "strace "

  s &= getAppDir() & "/ferus_process --kind:" & $(summon.process.kind.int)

  if summon.process.kind == Parser:
    s &= " --pKind:" & $(summon.process.pKind.int)

  s &= " --ipc-path:" & $summon.ipcPath

  s

proc summon*(
    kind: FerusProcessKind,
    pKind: ParserKind = pkCSS, # TODO: implement pkNone
    ipcPath: string,
): Summon {.inline.} =
  var process = FerusProcess(kind: kind)

  if kind == Parser:
    process.pKind = pKind

  Summon(process: process, ipcPath: ipcPath)
