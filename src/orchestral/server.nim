#[
  Task scheduler for Ferus main process, do not use this standalone as this is very opinionated towards Ferus.
  Just write your own, it will save you a lot more pain than copy pasting this garbage.

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#

import ../ipc/server,
       chronicles, times

type OrchestralServer* = ref object of RootObj
  server*: tuple[cooldown: float32, context: IPCServer] # the IPC client

  serverLastUpdated*: float
  lastCpuTime*: float

proc updateServer*(orchestral: OrchestralServer, delta: float) {.inline.} =
  if orchestral.server.context.isNil:
    warn "[src/orchestral/server.nim] Scheduler was passed `nil` instead of src.ipc.client.Client; this function won't execute further to prevent a crash."
    return

  if orchestral.serverLastUpdated >= orchestral.server.cooldown:
    orchestral.server.context.heartbeat()
    orchestral.serverLastUpdated = 0f
  else:
    orchestral.serverLastUpdated += 1f + delta

proc update*(orchestral: OrchestralServer) {.inline.} =
  let delta = cpuTime() - orchestral.lastCpuTime
  orchestral.lastCpuTime = 0f
  orchestral
    .updateServer(delta)

proc newOrchestralServer*(iserver: IPCServer): OrchestralServer {.inline.} =
  OrchestralServer(
    server: (cooldown: 2f, context: iserver),
    lastCpuTime: cpuTime()
  )
