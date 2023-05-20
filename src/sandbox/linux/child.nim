#[
  The "child" process -- this is executed by src/libferuscli.nim everytime it needs to spin up a new child process

  This code is licensed under the MIT license
]#

import sandbox,
       os, tables, strutils, chronicles,
       ../../ipc/[client, constants],
       ../../sandbox/processtypes,
       ../processtypes


type ChildProcess* = ref object of RootObj
  ipcClient*: IPCClient
  sandbox*: FerusSandbox

proc init*(childProc: ChildProcess) =
  childProc.sandbox.beginSandbox()

proc handshake*(childProc: ChildProcess) =
  info "[src/sandbox/linux/child.nim] i can haz hendshek?"
  childProc.ipcClient.handshakeBegin()

proc newChildProcess*(procType: ProcessType, brokerAffinitySignature: string): ChildProcess =
  # Note to all developers -- do NOT add any code before the sandbox is initialized!
  var sandbox = newFerusSandbox(procType)
  var ipc = newIPCClient(brokerAffinitySignature)

  ChildProcess(sandbox: sandbox, ipcClient: ipc)
