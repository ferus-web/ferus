import chronicles, os, ../../ipc/server


type Broker* = ref object of RootObj
  ipcServer*: IPCServer
  tab*: Tab
