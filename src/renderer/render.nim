import opengl, chronicles, pixie, windy

type 
  DrawListener* = proc(window: Window)
  Renderer* = ref object of RootObj
    window*: Window
    drawListeners*: seq[DrawListener]

proc onRender*(renderer: Renderer) =
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glClearColor(0f, 0.5f, 0.5f, 1f)

  for fn in renderer.drawListeners:
    fn(renderer.window)
  renderer.window.swapBuffers()
  pollEvents()

proc attachToRender*(renderer: Renderer, fn: DrawListener) =
  renderer.drawListeners.add(fn)

proc init*(renderer: Renderer) =
  while not renderer.window.closeRequested:
    renderer.onRender()

proc newRenderer*: Renderer =
  info "[src/renderer/render.nim] Instantiating renderer"
  loadExtensions()
  
  var window = newWindow("Ferus -- initializing!", ivec2(1280, 720))
  window.makeContextCurrent()
  
  info "[src/renderer/render.nim] Renderer initialized"
  Renderer(window: window)
