#[
  This code is licensed under the MIT license
]#

import os, strutils
import sandbox/processtypes, 
       renderer/sandboxed, 
       orchestral/client,
       ipc/client,
       renderer/render

when defined(linux):
  import sandbox/linux/child
  import std/posix
  
import chronicles

proc summon*(procRole: ProcessType, 
             brokerAffinitySignature: string, ipcServerPort: int) =
  info "[src/feruschild.nim] Ejecting from parent!"
  var 
    sRenderer: SandboxedRenderer
    orchestralClient: OrchestralClient
    uRenderer = newRenderer(1280, 720)
  
  when defined(ferusForkStrategy):
    var pid = fork()
    info "[src/feruschild.nim] Using forking strategy, this is not supported and a bad idea! (Ferus was compiled with -d:ferusForkStrategy)"
    if pid == -1:
      fatal "[src/feruschild.nim] Fork failed -- abort."
      quit 1
    elif pid == 0:
      info "[src/feruschild.nim] Fork successful."
    else:
      info "[src/feruschild.nim] Waiting for proper fork"
      var status = 0
      # how tf do you use waitpid?

  info "[src/feruschild.nim] We are now a child process."
  var sandboxedProcess = newChildProcess(procRole, brokerAffinitySignature, ipcServerPort)
  sandboxedProcess.init()

  if procRole == ptRenderer:
    info "[src/feruschild.nim] Renderer is initializing in sandboxed mode!"
    sRenderer = newSandboxedRenderer(sandboxedProcess, uRenderer)
    sRenderer.initialize()

  orchestralClient = newOrchestralClient(
    uRenderer, sandboxedProcess.ipcClient
  )

  while true:
    if orchestralClient.update():
      info "[src/feruschild.nim] Orchestral client shutting down..."
      sandboxedProcess.ipcClient.kill()
      break
