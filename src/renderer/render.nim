import opengl, chronicles, pixie, windy, boxy

type 
  DrawListener* = proc(window: Window, surface: Image)
  Renderer* = ref object of RootObj
    window*: Window
    drawListeners*: seq[DrawListener]
    width*: int
    height*: int
    boxy*: Boxy

proc onRender*(renderer: Renderer) =
  let surface = newImage(renderer.width, renderer.height)
  surface.fill(rgba(255, 255, 255, 255))
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearColor(0f, 0.5f, 0.5f, 1f)

  for fn in renderer.drawListeners:
    fn(renderer.window, surface)
  
  renderer.boxy.addImage("surface", surface, genMipmaps=false)
  renderer.boxy.beginFrame(renderer.window.size)
  renderer.boxy.drawImage("surface", vec2(0, 0))
  renderer.boxy.endFrame()
  renderer.window.swapBuffers()
  pollEvents()

proc drawText*(renderer: Renderer, text: string, 
               pos: tuple[x: float32, y: float32], scale: tuple[w: float32, h: float32],
               font: Font, surface: Image) =
  surface.fillText(
    font.typeset(
      text, 
      vec2(pos.x, pos.y)
    ), 
    translate(
      vec2(scale.w, scale.h)
    )
  )

proc blurImg*(renderer: Renderer, img: Image, strength: int = 8): Image =
  img.blur(strength.float)

  return img

proc onResize*(renderer: Renderer) =
  var
    width = renderer.window.size.x
    height = renderer.window.size.y
  
  when defined(ferusExtraVerboseLogging):
    info "[src/renderer/render.nim] Window resizing!", width=width, height=height

  renderer.width = width
  renderer.height = height

proc attachToRender*(renderer: Renderer, fn: DrawListener) =
  renderer.drawListeners.add(fn)

proc init*(renderer: Renderer) =
  while not renderer.window.closeRequested:
    renderer.onRender()

proc newRenderer*(height, width: int): Renderer =
  info "[src/renderer/render.nim] Instantiating renderer"
  loadExtensions()
  
  var window = newWindow("Ferus -- initializing!", ivec2(width.int32, height.int32))
  window.makeContextCurrent()
  window.title = "Ferus"
  
  info "[src/renderer/render.nim] Renderer initialized"
  var renderer = Renderer(window: window, width: width, height: height, 
                          boxy: newBoxy())
  proc iOnResize() =
    renderer.onResize()

  window.onResize = iOnResize

  renderer
