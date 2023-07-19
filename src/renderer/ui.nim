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
  backgroundColor*: ColorRGBA

proc loadIcon*(ui: UI) {.inline.} =
  info "[src/renderer/ui.nim] Loading Ferus icon!"
  let logo = readImage("../data/ferus_logo.png")
  ui.renderer.setIcon(logo)

proc blit*(ui: UI, surface: RenderImage) =
  surface.img.fill(ui.backgroundColor)
  ui.layoutEngine.draw(surface)

proc init*(ui: UI) =
  proc iOnRender(window: Window, surface: RenderImage) =
    ui.blit(surface)
  
  ui.layoutEngine.calculate()

  ui.loadIcon()
  ui.renderer.attachToRender(iOnRender)
  ui.renderer.init()

proc newUI*(dom: DOM, renderer: Renderer): UI =
  UI(renderer: renderer, 
     layoutEngine: newLayoutEngine(dom, renderer),
     backgroundColor: rgba(255, 255, 255, 255)
  )
