#[
  Task scheduler for Ferus main process, do not use this standalone as this is very opinionated towards Ferus.
  Just write your own, it will save you a lot more pain than copy pasting this garbage.

  This code is licensed under the MIT license
]#

import ../ipc/server,
       chronicles

type OrchestralServer* = ref object of RootObj
  server*: tuple[cooldown: float32, context: IPCServer] # the IPC client

  serverLastUpdated*: float

proc updateClient*(orchestral: OrchestralServer) =
  if orchestral.server.context.isNil:
    warn "[src/orchestral/orchestral.nim] Scheduler was passed `nil` instead of src.ipc.client.Client; this function won't execute further to prevent a crash."
    return

  if orchestral.serverLastUpdated >= orchestral.server.cooldown:
    when defined(ferusUseVerboseLogging):
      info "[src/orchestral/orchestral.nim] Updating IPC client state!"

    orchestral.server.context.heartbeat()
    orchestral.serverLastUpdated = 0f
  else:
    orchestral.serverLastUpdated += 0.1f

proc update*(orchestral: OrchestralServer) =
  orchestral
    .updateClient()

proc newOrchestralServer*(iserver: IPCServer): OrchestralServer =
  OrchestralServer(
    server: (cooldown: 8f, context: iserver)
  )
