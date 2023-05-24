#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/[client, constants],
       ../dom/dom,
       ui, render, ../orchestral/client,
       ../layout/layout
import std/[json, marshal, tables, strutils, os], chronicles

when defined(linux):
  import ../sandbox/linux/sandbox
  import ../sandbox/linux/child


type SandboxedRenderer* = ref object of RootObj
  child*: ChildProcess
  ui*: UI
  renderer*: Renderer

proc startUI*(sandboxedRenderer: SandboxedRenderer, dom: DOM) =
  var 
    ui = newUI(dom, sandboxedRenderer.renderer)

  sandboxedRenderer.ui = ui
  sandboxedRenderer.ui.init()

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.child.handshake()
  info "[src/renderer/sandboxed.nim] Request IPC server for DOM"
  sandboxedRenderer.child.ipcClient.send(
    {
      "result": IPC_CLIENT_NEEDS_DOM
    }.toTable
  )

  proc domRecv(data: JSONNode) =
    if "result" in data:
      if data["result"].getStr().parseInt() == PACKET_TYPE_DOM:
        info "[src/renderer/sandboxed.nim] Received DOM; layout engine start!"
        var dom = to[DOM](data["payload"].getStr())
        sandboxedRenderer.startUI(dom)
     
  sandboxedRenderer.child.ipcClient.addReceiver(domRecv)

proc newSandboxedRenderer*(child: ChildProcess, renderer: Renderer): SandboxedRenderer =
  SandboxedRenderer(child: child, renderer: renderer)
