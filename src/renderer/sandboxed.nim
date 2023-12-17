#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/[client, constants],
       ../dom/dom,
       render, windy
import std/[json, marshal, tables, strutils, os], chronicles, pixie


type SandboxedRenderer* = ref object of RootObj
  renderer*: Renderer
  ipcClient*: IPCClient

proc startUI*(sandboxedRenderer: SandboxedRenderer, dom: DOM) {.inline.} =
  echo "start UI or smt idk"

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  info "[src/renderer/sandboxed.nim] Request IPC server for DOM"
  sandboxedRenderer.ipcClient.send(
    {
      "result": IPC_CLIENT_NEEDS_DOM
    }.toTable
  )

  proc domRecv(data: JSONNode) =
    echo pretty data
    if "result" in data:
      if data["result"].getStr().parseInt() == PACKET_TYPE_DOM:
        info "[src/renderer/sandboxed.nim] Received DOM; layout engine starting!"
        var dom = to[DOM](data["payload"].getStr())
        sandboxedRenderer.startUI(dom)
      else:
        warn "[src/renderer/sandboxed.nim] IPC server did not give us a packet with PACKET_TYPE_DOM."
    else:
      warn "[src/renderer/sandboxed.nim] IPC server did not return proper DOM data."
      echo $data
     
  sandboxedRenderer.ipcClient.addReceiver(domRecv)

proc newSandboxedRenderer*(ipcClient: IPCClient, renderer: Renderer): SandboxedRenderer =
  SandboxedRenderer(ipcClient: ipcClient, renderer: renderer)
