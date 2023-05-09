#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/client
import render
import ui

when defined(linux):
  import ../sandbox/linux/sandbox
  import ../sandbox/linux/child


type SandboxedRenderer* = ref object of RootObj
  child*: ChildProcess
  sandbox*: FerusSandbox
  ui*: UI

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.ui.init()

proc newSandboxedRenderer*(child: ChildProcess): SandboxedRenderer =
  var 
    renderer = newRenderer(1280, 1080)
  SandboxedRenderer(ui: newUI(renderer), child: child)
