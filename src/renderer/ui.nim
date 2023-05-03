import gintro/[gtk4, gobject, gio]
import chronicles

type UI* = ref object of RootObj
  app*: Application

var 
  window: ApplicationWindow
  ui: UI

proc setTitle*(ui: UI, title: string) =
  window.title = "Ferus — " & title

proc setWindowSize*(ui: UI, size: tuple[w: int, h: int]) =
  window.defaultSize = (size.w, size.h)

proc initialize*(app: Application) =
  info "[src/renderer/ui.nim] Using GTK as backend; initializing!"
  window = newApplicationWindow(app)
  ui.setTitle("initializing!")
  ui.setWindowSize((w: 200, h: 200))

  window.show()

proc newUI*: UI =
  var app = newApplication("io.github.xtrayambak.ferus")
  ui = UI(app: app)

  discard connect(app, "activate", initialize)
  discard run(app)
  ui
