#[
  The "child" process -- this is executed by src/libferuscli.nim everytime it needs to spin up a new child process

  This code is licensed under the MIT license
]#

import sandbox,
       os, tables,
       ../../ipc/client,
       ../processtypes


type ChildProcess* = ref object of RootObj
  ipcClient*: IPCClient
  sandbox*: FerusSandbox

proc init*(childProc: ChildProcess) =
  childProc.sandbox.beginSandbox()

proc newChildProcess*(procType: ProcessType, brokerAffinitySignature: string): ChildProcess =
  # Note to all developers -- do NOT add any code before the sandbox is initialized!
  var sandbox = newFerusSandbox(8089, procType)
  var ipc = newIPCClient(brokerAffinitySignature)

  ChildProcess(sandbox: sandbox, ipcClient: ipc)
