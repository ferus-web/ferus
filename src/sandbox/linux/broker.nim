import chronicles, osproc, strformat,
       ../../ipc/server,
       ../../sandbox/processtypes


type Broker* = ref object of RootObj
  ipcServer*: IPCServer

proc createNewProcess(broker: Broker, procType: ProcessType) =
  info "[src/sandbox/linux/broker.nim] Broker is creating new process!"

  discard execProcess("libferuscli", args=[fmt"--role={processTypeToString()}"])
