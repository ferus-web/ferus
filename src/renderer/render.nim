import opengl, chronicles, 
       pixie, windy, 
       boxy, weave, 
       os, primitives

const FERUS_RENDER_PIPELINE_NUMTHREADS {.intdefine.} = 4

type
  DrawListener* = proc(window: Window, surface: RenderImage)
  Renderer* = ref object of RootObj
    window*: Window
    drawListeners*: seq[DrawListener]
    width*: int
    height*: int
    boxy*: Boxy
    alive*: bool
    glVersion*: string
    glVendor*: string
    glRenderer*: string
  
proc newRenderImage*(img: Image): RenderImage =
  RenderImage(img: img, blurEnabled: false)

proc setIcon*(renderer: Renderer, image: Image) =
  # Ferus should only support 64x64 icons
  if not renderer.isNil:
    assert image.height == 64 and image.width == 64
    renderer.window.icon = image
  else:
    warn "[src/renderer/render.nim] setIcon() failed as renderer has not yet been initialized."

proc onRender*(renderer: Renderer) =
  let surface = newRenderImage(newImage(renderer.width, renderer.height))

  surface.img.fill(rgba(255, 255, 255, 255))

  # Clear the screen
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearColor(0f, 0.5f, 0.5f, 1f)
  
  # You should manipulate the frame in the functions here, to prevent clutter.
  for fn in renderer.drawListeners:
    fn(renderer.window, surface)

  # Just render the image to the screen
  renderer.boxy.addImage("surface", surface.img)
  renderer.boxy.beginFrame(renderer.window.size)
  renderer.boxy.drawImage("surface", vec2(0, 0))
  renderer.boxy.endFrame()
  renderer.window.swapBuffers()
  
  # Poll GLFW events
  pollEvents()

proc drawText*(renderer: Renderer, text: string, 
               pos: tuple[x: float32, y: float32], scale: tuple[w: float32, h: float32],
               font: Font, surface: RenderImage) =
  surface.img.fillText(
    font.typeset(
      text, 
      vec2(pos.x, pos.y)
    ), 
    translate(
      vec2(scale.w, scale.h)
    )
  )

proc blurImg*(renderer: Renderer, renderImg: RenderImage, strength: int = 2) =
  if renderer.alive and not renderImg.blurEnabled:
    renderImg.blurEnabled = true

    init(Weave)
    spawn renderImg.img.blur(strength.float32)
    exit(Weave)

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
  var
    glVersion = $cast[cstring](glGetString(GL_VERSION))
    glVendor = $cast[cstring](glGetString(GL_VENDOR))
    glRenderer = $cast[cstring](glGetString(GL_RENDERER))

  renderer.glVersion = glVersion
  renderer.glVendor = glVendor
  renderer.glRenderer = glRenderer
 
proc newRenderer*(height, width: int): Renderer =
  info "[src/renderer/render.nim] Instantiating renderer"
  loadExtensions()
  
  var window = newWindow("Ferus -- initializing!", ivec2(width.int32, height.int32))
  window.makeContextCurrent()
  window.title = "Ferus"
  
  info "[src/renderer/render.nim] Renderer initialized"
  var renderer = Renderer(window: window, width: width, height: height, 
                          boxy: newBoxy(), alive: true)
  proc iOnResize() =
    renderer.onResize()

  window.onResize = iOnResize

  renderer
