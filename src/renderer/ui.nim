import render, windy, pixie, tables, chronicles

var x = 80f

type UI* = ref object of RootObj
  renderer*: Renderer
  fonts*: TableRef[string, Font]

proc getFont*(ui: UI, fontName: string): Font =
  ui.fonts[fontName]

proc addFont*(ui: UI, name: string, path: string) =
  if name in ui.fonts:
    warn "[src/renderer/ui.nim] Overwriting existing entry for font!", fontName=name

  ui.fonts[name] = readFont(path)

proc blit*(ui: UI, surface: Image) =
  # > be me
  # > load font every frame
  # > CPU screeches in agony, kernel OOM mechanism constantly kills Ferus
  # > confused, refuse to elaborate
  #[var font = readFont("../data/IBMPlexSans-Bold.ttf")
  font.size = 20]#

  var font = ui.getFont("Default")

  x += 0.5
  
  ui.renderer.drawText("Hello Ferus!", (x: x + 0.0f, y: 600f), (w: 240f, h: 180f), font, surface)
  var x = ui.renderer.blurImg(surface)

proc init*(ui: UI) =
  proc iOnRender(window: Window, surface: Image) =
    ui.blit(surface)
  
  ui.addFont("Default", "../data/IBMPlexSans-Bold.ttf")
  ui.renderer.attachToRender(iOnRender)
  ui.renderer.init()

proc newUI*(renderer: Renderer): UI =
  UI(renderer: renderer, fonts: newTable[string, Font]())
