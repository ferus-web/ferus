#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/[client, constants],
       ../dom/dom,
       ui, render, windy,
       ../layout/layout
import std/[json, marshal, tables, strutils, os], chronicles, pixie, ferushtml


type SandboxedRenderer* = ref object of RootObj
  ui*: UI
  renderer*: Renderer
  ipcClient*: IPCClient

proc startUI*(sandboxedRenderer: SandboxedRenderer, dom: DOM) {.inline.} =
  var 
    ui = newUI(dom, sandboxedRenderer.renderer)

  sandboxedRenderer.ui = ui
  sandboxedRenderer.ui.init()

  for child in dom.document.root.findChildByTag("html").findChildByTag("head").children:
    if child.tag.toLowerAscii() == "title":
      sandboxedRenderer.renderer.window.title = "Ferus — " & child.textContent

  # TODO(xTrayambak): this should be handled in a seperate file to prevent clutter
  for attr in dom.document.root.findChildByTag("html").findChildByTag("body").attributes:
    if attr.name.toLowerAscii() == "background-color":
      sandboxedRenderer.ui.backgroundColor = parseHtmlColor(attr.value.payload).rgba

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  info "[src/renderer/sandboxed.nim] Request IPC server for DOM"
  sandboxedRenderer.ipcClient.send(
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
     
  sandboxedRenderer.ipcClient.addReceiver(domRecv)

proc newSandboxedRenderer*(ipcClient: IPCClient, renderer: Renderer): SandboxedRenderer =
  SandboxedRenderer(ipcClient: ipcClient, renderer: renderer)
