#[
  This code is licensed under the MIT license
]#

import os, strutils
import sandbox/processtypes, renderer/sandboxed, orchestral/client

when defined(linux):
  import sandbox/linux/child
  import std/posix
  
import chronicles

proc summon*(procRole: ProcessType, 
            brokerAffinitySignature: string) =
  info "[src/feruschild.nim] Ejecting from parent!"
  discard fork()

  info "[src/feruschild.nim] We are now a child process."
  var sandboxedProcess = newChildProcess(procRole, brokerAffinitySignature)
  sandboxedProcess.init()

  if procRole == ptRenderer:
    info "[src/feruschild.nim] Renderer is initializing in sandboxed mode!"
    var sRenderer = newSandboxedRenderer(sandboxedProcess)
    sRenderer.initialize()
