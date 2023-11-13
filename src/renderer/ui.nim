import windy, pixie, 
       chronicles, pretty,
       tables,
       render,
       primitives,
       ../dom/dom,
<<<<<<< HEAD
       ../layout/layout

type UI* = ref object of RootObj
  renderer*: Renderer
  layoutEngine*: LayoutEngine
=======
       ../layout/[processor, aabb, node]

type UI* = ref object of RootObj
  renderer*: Renderer
  layout*: LayoutProcessor
>>>>>>> 5576c29 ((fix) some stuff)
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
  
<<<<<<< HEAD
  ui.layoutEngine.calculate()
=======
  ui.layout.nodes.add(
    newLayoutNode("p", lnkGeneric, AABB(x: 0, y: 0, w: 16, h: 16))
  )
  ui.layout.calculate()

  print ui.layout
>>>>>>> 5576c29 ((fix) some stuff)

  ui.loadIcon()
  ui.renderer.attachToRender(iOnRender)
  ui.renderer.init()

proc newUI*(dom: DOM, renderer: Renderer): UI =
  UI(renderer: renderer, 
     layoutEngine: newLayoutEngine(dom, renderer),
     backgroundColor: rgba(255, 255, 255, 255)
  )
