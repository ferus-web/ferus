#[
  Command line helper to start child processes (w/ brokers) for Ferus, similar to the chrome-wrapper executable

  This code is licensed under the MIT license
]#

import os, strutils
import sandbox/processtypes, renderer/sandboxed

when defined(linux):
  import sandbox/linux/child
  
import chronicles

proc getFlagAt(idx: int): string =
  if idx > paramCount():
    error "[src/libferuscli.nim] getFlagAt() failed, idx > os.paramCount()"
    quit()

  paramStr(idx).strip(chars = {'-', '-'}).toLowerAscii()

proc clean(s: string): string =
  var
    idx = -1
    builder = ""

  for c in s:
    inc idx
    if idx > 4:
      builder = builder & c

  builder

proc getProcessRole*(): ProcessType =
  if getFlagAt(1).startswith("role"):
    var role = getFlagAt(1).clean()
    if role == "net":
      return ProcessType.ptNetwork
    elif role == "renderer":
      return ProcessType.ptRenderer
    elif role == "html":
      return ProcessType.ptHtmlParser
    elif role == "css":
      return ProcessType.ptCssParser
    elif role == "bali":
      return ProcessType.ptBaliRuntime
    else:
      error "[src/libferuscli.nim] Could not determine ProcessType", roleGiven=role
      quit()

proc main =
  var initialFlag = getFlagAt(0)
  if initialFlag.len < 1:
    error "[src/libferuscli.nim] Expected arguments, got none."
    quit()

  var procRole = getProcessRole()

  var sandboxedProcess = newChildProcess(procRole)
  sandboxedProcess.init()

  if procRole == ptRenderer:
    info "[src/libferuscli.nim] Renderer is initializing in sandboxed mode!"
    var sRenderer = newSandboxedRenderer()
    sRenderer.initialize()
  else:
    echo procRole


main()
