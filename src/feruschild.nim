#[
  This code is licensed under the MIT license
]#

import os, strutils
import sandbox/processtypes, 
       renderer/sandboxed, 
       orchestral/client,
       ipc/client,
       renderer/render

import chronicles

proc summon*(procRole: ProcessType, 
             brokerAffinitySignature: string, ipcServerPort: int) =
  info "[src/feruschild.nim] Ejecting from parent!"
  var 
    sRenderer: SandboxedRenderer
    orchestralClient: OrchestralClient
    uRenderer = newRenderer(1280, 720)
  
  info "[src/feruschild.nim] We are now a child process."

  var ipcClient = newIPCClient(brokerAffinitySignature, ipcServerPort)
  ipcClient.handshake()

  if procRole == ptRenderer:
    info "[src/feruschild.nim] Renderer is initializing in sandboxed mode!"
    sRenderer = newSandboxedRenderer(ipcClient, uRenderer)
    sRenderer.initialize()

  orchestralClient = newOrchestralClient(
    uRenderer, ipcClient 
  )

  while true:
    if orchestralClient.update():
      info "[src/feruschild.nim] Orchestral client shutting down..."
      ipcClient.kill()
      break
