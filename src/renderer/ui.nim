import windy, pixie, 
       chronicles,
       tables,
       render,
       primitives,
       ../dom/dom,
       ../layout/layout

type UI* = ref object of RootObj
  renderer*: Renderer
  layoutEngine*: LayoutEngine
  fonts*: TableRef[string, Font]

proc loadIcon*(ui: UI) {.inline.} =
  info "[src/renderer/ui.nim] Loading Ferus icon!"
  ui.renderer.setIcon(readImage("../data/ferus_logo.png"))

proc blit*(ui: UI, surface: RenderImage) =
  ui.layoutEngine.processLayout(surface)

proc init*(ui: UI) =
  proc iOnRender(window: Window, surface: RenderImage) =
    ui.blit(surface)
  
  ui.loadIcon()
  ui.renderer.attachToRender(iOnRender)
  ui.renderer.init()

proc newUI*(dom: DOM, renderer: Renderer): UI =
  UI(renderer: renderer, 
     fonts: newTable[string, Font](), layoutEngine: newLayoutEngine(dom, renderer)
  )
