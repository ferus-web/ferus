#[
  Command line helper to start child processes (w/ brokers) for Ferus, similar to the chrome-wrapper executable

  This code is licensed under the MIT license
]#

import os, strutils
import sandbox/processtypes, 
       renderer/sandboxed,
       feruschild

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
    builder = ""
    canWriteArgNow = false

  for c in s:
    if c == '=':
      canWriteArgNow = true
      continue
    
    if canWriteArgNow:
      builder = builder & c

  builder

proc getProcessRole*(): ProcessType {.inline.} =
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
      quit(1)
  else:
    error "[src/libferuscli.nim] Process role must always be the first argument, this will be fixed in the future."
    quit(1)

proc getUnixTimeOfLaunch*(): uint64 {.inline.} =
  if getFlagAt(2).startswith("unix-time-at-launch"):
    return parseInt(getFlagAt(2).clean()).uint64
  else:
    error "[src/libferuscli.nim] Launch time (in UNIX time) must always be the second argument, this will be fixed in the future."
    quit(1)

proc getBrokerAffinitySignature*(): string {.inline.} =
  if getFlagAt(3).startswith("broker-affinity-signature"):
    return getFlagAt(3).clean()
  else:
    error "[src/libferuscli.nim] Broker affinity signature must always be the third argument, this will be fixed in the future."
    quit(1)

proc getIPCServerPort*(): int {.inline.} =
  if getFlagAt(4).startswith("ipc-server-port"):
    return getFlagAt(4)
          .clean()
          .parseInt()
  else:
    error "[src/libferuscli.nim] IPC server port must always be the fourth argument, this will be fixed in the future."
    quit(1)

proc main =
  var initialFlag = getFlagAt(0)
  if initialFlag.len < 1:
    error "[src/libferuscli.nim] Expected arguments, got none."
    quit(1)

  var 
    procRole = getProcessRole()
    brokerAffinitySignature = getBrokerAffinitySignature()
    ipcServerPort = getIPCServerPort()
  summon(procRole, brokerAffinitySignature, ipcServerPort)

main()
