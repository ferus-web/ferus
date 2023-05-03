#[
  Each tab has it's own DOM and JS runtime.

  This code is licensed under the MIT license
]#
import chronicles
import dom/dom
import ipc/server

when defined(linux):
  import sandbox/linux/broker

type Tab* = ref object of RootObj
  dom*: DOM
  ipcServer*: IPCServer
  broker*: Broker

proc initialize*(tab: Tab) =
  info "[src/tab.nim] Initializing!"

proc newTab*(dom: DOM, ipcServer: IPCServer, broker: Broker): Tab =
  Tab(dom: dom, ipcServer: ipcServer, broker: broker)
