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

proc loadIcon*(ui: UI) {.inline.} =
  info "[src/renderer/ui.nim] Loading Ferus icon!"
  let logo = readImage("../data/ferus_logo.png")
  ui.renderer.setIcon(logo)

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
     layoutEngine: newLayoutEngine(dom, renderer)
  )
