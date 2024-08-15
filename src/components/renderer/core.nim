import std/[options, strutils, importutils, logging]
import ferusgfx, ferus_ipc/client/prelude
import opengl

when defined(ferusUseGlfw):
  import glfw
else:
  import windy

type FerusRenderer* = ref object
  window*: Window
  ipc*: IPCClient
  scene*: Scene

proc mutate*(renderer: FerusRenderer, list: Option[DisplayList]) {.inline.} =
  if not *list:
    error "Cannot mutate scene tree - could not reinterpret JSON data as `DisplayList`!"

  info "Mutating scene tree"

  var dlist = &list
  privateAccess(DisplayList) # FIXME: make `DisplayList`'s `scene` pointer public!

  dlist.scene = addr renderer.scene

  info "Committing display list."
  commit dlist

proc tick*(renderer: FerusRenderer) {.inline.} =
  renderer.scene.draw()
  renderer.window.swapBuffers()

  when defined(ferusUseGlfw):
    glfw.pollEvents()
  else:
    pollEvents()

  #privateAccess renderer.scene.camera.typeof
  #renderer.ipc.debug $renderer.scene.camera.delta

proc close*(renderer: FerusRenderer) {.inline.} =
  info "Closing renderer."

  when defined(ferusUseGlfw):
    glfw.terminate()
    destroy renderer.window

proc setWindowTitle*(renderer: FerusRenderer, title: string) {.inline.} =
  info "Setting window title to \"" & title & "\""
  renderer.window.title = title

proc resize*(renderer: FerusRenderer, dims: tuple[w, h: int32]) {.inline.} =
  info "Resizing renderer viewport to $1x$2" % [$dims.w, $dims.h]
  let casted = (w: dims.w.int, h: dims.h.int)
  renderer.scene.onResize(casted)

proc initialize*(renderer: FerusRenderer) {.inline.} =
  info "Initializing renderer."
  # glfw.initialize()
  loadExtensions()
  
  when defined(ferusUseGlfw):
    var conf = DefaultOpenglWindowConfig
    conf.title = "Ferus"
    conf.size = (w: 1280, h: 1080)
    conf.makeContextCurrent = true
    conf.version = glv30

    var window = try:
      newWindow(conf)
    except GLFWError as exc:
      error "Failed to initialize GLFW window: " & exc.msg
      quit(8)
  else:
    var window = newWindow(
      "Ferus", ivec2(1280, 720)
    )
    window.makeContextCurrent()
  
  renderer.window = window
  renderer.scene = newScene(1280, 1080)
  
  when defined(ferusUseGlfw):
    window.windowSizeCb = proc(_: Window, size: tuple[w, h: int32]) =
      renderer.resize(size)

    window.scrollCb = proc(_: Window, offset: tuple[x, y: float64]) =
      # renderer.ipc.debug "Scrolling (offset: " & $offset & ")"
      let casted = vec2(offset.x, offset.y)
      renderer.scene.onScroll(casted)

    # window.registerWindowCallbacks()
    renderer.window = window
  else:
    window.onResize = proc =
      renderer.resize((w: window.size.x.int32, h: window.size.x.int32))

    window.onScroll = proc =
      renderer.scene.onScroll(
        vec2(window.scrollDelta.x, window.scrollDelta.y)
      )

proc newFerusRenderer*(client: var IPCClient): FerusRenderer {.inline.} =
  FerusRenderer(ipc: client)
