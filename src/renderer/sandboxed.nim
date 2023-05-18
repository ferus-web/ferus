#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/[client, constants],
       ../dom/dom,
       ui, render, ../orchestral/client,
       ../layout/layout
import std/[json, marshal, tables, strutils]

when defined(linux):
  import ../sandbox/linux/sandbox
  import ../sandbox/linux/child


type SandboxedRenderer* = ref object of RootObj
  child*: ChildProcess
  ui*: UI

proc startUI*(sandboxedRenderer: SandboxedRenderer, dom: DOM) =
  var 
    renderer = newRenderer(1280, 720)
    ui = newUI(dom, renderer)

  sandboxedRenderer.ui = ui
  sandboxedRenderer.ui.init()

  var orchestralClient = newOrchestralClient(
    sandboxedRenderer.ui.renderer, 
    sandboxedRenderer.child.ipcClient
  )
  
  while true:
    orchestralClient.update()

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.child.ipcClient.send(
    {
      "result": IPC_CLIENT_NEEDS_DOM
    }.toTable
  )
  proc domRecv(data: JSONNode) =
    if "result" in data:
      if data["result"].getStr().parseInt() == PACKET_TYPE_DOM:
        var dom = to[DOM](data.getStr())
        sandboxedRenderer.startUI(dom)
      else:
        echo "EEEEEEEEEEEEEEEEEEE"
    else:
      echo $data

  sandboxedRenderer.child.ipcClient.addReceiver(domRecv)

proc newSandboxedRenderer*(child: ChildProcess): SandboxedRenderer =
  SandboxedRenderer(child: child)
