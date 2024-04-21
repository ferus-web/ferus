import ferus_ipc/server/prelude

type
  MasterProcess* = ref object
    server*: IPCServer

proc initialize*(master: MasterProcess) {.inline.} =
  master.server.add(FerusGroup())
  master.server.initialize()

proc poll*(master: MasterProcess) {.inline.} =
  master.server.poll()

proc newMasterProcess*: MasterProcess {.inline.} =
  MasterProcess(
    server: newIPCServer()
  )
