#[
  Task scheduler for Ferus child processes, do not use this standalone as this is very opinionated towards Ferus.
  Just write your own, it will save you a lot more pain than copy pasting this garbage.

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#

import ../renderer/render,
       ../ipc/client,
       times,
       pixie,
       windy,
       chronicles

type OrchestralClient* = ref object of RootObj
  renderer*: tuple[cooldown: float32, context: Renderer] # The renderer context
  client*: tuple[cooldown: float32, context: IPCClient] # the IPC client

  clientLastUpdated*: float    # Time since IPC client got updated
  rendererLastUpdated*: float  # Time since renderer got updated (only necessary for ptRenderer processes)

  lastCpuTime*: float

proc updateRenderer*(orchestral: OrchestralClient, delta: float) {.inline.} =
  if orchestral.renderer.context.isNil:
    when defined(ferusUseVerboseLogging):
      warn "[src/orchestral/orchestral.nim] Scheduler was passed `nil` instead of src.renderer.render.Renderer; this function won't execute further to prevent a crash."
    return

  if orchestral.rendererLastUpdated >= orchestral.renderer.cooldown:
    when defined(ferusUseVerboseLogging):
      info "[src/orchestral/orchestral.nim] Updating renderer state!"

    orchestral.renderer.context.onRender()
  else:
    orchestral.rendererLastUpdated += delta

proc updateClient*(orchestral: OrchestralClient, delta: float) {.inline.} =
  if orchestral.client.context.isNil:
    when defined(ferusUseVerboseLogging):
      warn "[src/orchestral/orchestral.nim] Scheduler was passed `nil` instead of src.ipc.client.Client; this function won't execute further to prevent a crash."
    return

  if orchestral.clientLastUpdated >= orchestral.client.cooldown:
    when defined(ferusUseVerboseLogging):
      info "[src/orchestral/orchestral.nim] Updating IPC client state!"

    orchestral.client.context.heartbeat()
    orchestral.clientLastUpdated = 0f
  else:
    orchestral.clientLastUpdated += 0.1f + delta

proc update*(orchestral: OrchestralClient): bool {.inline.} =
  let delta = cpuTime() - orchestral.lastCpuTime
  orchestral.lastCpuTime = cpuTime()

  orchestral.updateRenderer(delta)
  orchestral.updateClient(delta)
  
  if not orchestral.renderer.context.isNil:
    orchestral.renderer.context.window.closeRequested
  else:
    false

proc newOrchestralClient*(renderer: Renderer, 
                          client: IPCClient
                        ): OrchestralClient {.inline.} =
  OrchestralClient(renderer: (cooldown: 0f, context: renderer), 
                   client: (cooldown: 2f, context: client), lastCpuTime: cpuTime())