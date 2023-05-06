#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/client
import render
import ui

when defined(linux):
  import ../sandbox/linux/sandbox


type SandboxedRenderer* = ref object of RootObj
  ipcClient*: IPCClient
  renderer: Renderer
  ui*: UI

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.ui.init()

proc newSandboxedRenderer*: SandboxedRenderer =
  var 
    client = IPCClient()
    renderer = newRenderer(1280, 1080)
  SandboxedRenderer(ipcClient: client, ui: newUI(renderer))
