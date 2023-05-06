import render, windy, pixie, boxy

type UI* = ref object of RootObj
  renderer*: Renderer
  boxy*: Boxy

proc blit*(ui: UI) =
  let image = newImage(200, 200)
  image.fill(rgba(255, 255, 255, 255))

  var font = readFont("../data/IBMPlexSans-Bold.ttf")
  font.size = 20

  image.fillText(font.typeset("Hello Ferus!", vec2(180, 180)), translate(vec2(10, 10)))

  ui.boxy.addImage("frame", image, genMipmaps = false)

  ui.boxy.beginFrame(ui.renderer.window.size)
  ui.boxy.drawImage("frame", vec2(0, 0))
  ui.boxy.endFrame()

proc init*(ui: UI) =
  proc iOnRender(window: Window) =
    ui.blit()
  ui.renderer.attachToRender(iOnRender)
  ui.renderer.init()

proc newUI*: UI =
  UI(renderer: newRenderer(), boxy: newBoxy())
