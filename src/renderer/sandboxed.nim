#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/client,
       ../dom/dom
import render
import ui

when defined(linux):
  import ../sandbox/linux/sandbox
  import ../sandbox/linux/child


type SandboxedRenderer* = ref object of RootObj
  child*: ChildProcess
  ui*: UI

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.ui.init()

proc newSandboxedRenderer*(dom: DOM, child: ChildProcess): SandboxedRenderer =
  var 
    renderer = newRenderer(1280, 1080)
  SandboxedRenderer(ui: newUI(dom, renderer), child: child)
