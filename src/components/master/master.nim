import ferus_ipc/server/prelude

type
  MasterProcess* = ref object
    server*: IPCServer

proc newMasterProcess*: MasterProcess {.inline.} =
  MasterProcess(
    server: newIPCServer()
  )
