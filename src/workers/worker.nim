#[
  Short lived processes/workers (read src/workers/README.md)

  This code is licensed under the MIT license
]#
import ../ipc/client

type Worker* = ref object of RootObj
  ipcClient*: IPCClient