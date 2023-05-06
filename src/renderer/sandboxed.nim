#[
  The sandboxed renderer (only 1 has to be created per Ferus instance)
]#
import ../ipc/client
import ui

when defined(linux):
  import ../sandbox/linux/sandbox


type SandboxedRenderer* = ref object of RootObj
  ipcClient*: IPCClient
  ui*: UI

proc initialize*(sandboxedRenderer: SandboxedRenderer) =
  sandboxedRenderer.ui.init()

proc newSandboxedRenderer*: SandboxedRenderer =
  var client = IPCClient()
  SandboxedRenderer(ipcClient: client, ui: newUI())
