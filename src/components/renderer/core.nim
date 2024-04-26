import std/[options, strutils, importutils]
import ferusgfx, ferus_ipc/client/prelude
import glfw, opengl

type FerusRenderer* = ref object
  window*: Window
  ipc*: IPCClient
  scene*: Scene

proc mutate*(renderer: FerusRenderer, list: Option[DisplayList]) {.inline.} =
  if not *list:
    renderer.ipc.error "Cannot mutate scene tree - could not reinterpret JSON data as `DisplayList`!"

  renderer.ipc.info "Mutating scene tree"

  var dlist = &list
  privateAccess(DisplayList) # FIXME: make `DisplayList`'s `scene` pointer public!

  dlist.scene = addr renderer.scene

  renderer.ipc.info "Committing display list."
  commit dlist

proc tick*(renderer: FerusRenderer) {.inline.} =
  renderer.scene.draw()
  renderer.window.swapBuffers()
  glfw.pollEvents()

proc close*(renderer: FerusRenderer) {.inline.} =
  renderer.ipc.info "Closing renderer."
  glfw.terminate()
  destroy renderer.window

proc setWindowTitle*(renderer: FerusRenderer, title: string) {.inline.} =
  renderer.ipc.info "Setting window title to \"" & title & "\""
  renderer.window.title = title

proc resize*(renderer: FerusRenderer, dims: tuple[w, h: int32]) {.inline.} =
  renderer.ipc.info "Resizing renderer viewport to $1x$2" % [$dims.w, $dims.h]
  let casted = (w: dims.w.int, h: dims.h.int)
  renderer.scene.onResize(casted)

proc initialize*(renderer: FerusRenderer) {.inline.} =
  renderer.ipc.info "Initializing renderer."
  glfw.initialize()
  loadExtensions()

  var conf = DefaultOpenglWindowConfig
  conf.title = "Ferus"
  conf.size = (w: 640, h: 480)
  conf.makeContextCurrent = true

  var window = newWindow(conf)

  renderer.scene = newScene(640, 480)

  window.windowSizeCb = proc(_: Window, size: tuple[w, h: int32]) =
    renderer.resize(size)

  window.scrollCb = proc(_: Window, offset: tuple[x, y: float64]) =
    renderer.ipc.debug "Scrolling (offset: " & $offset & ")"
    renderer.scene.onScroll(vec2(offset.x, offset.y))

  # window.registerWindowCallbacks()
  renderer.window = window

proc newFerusRenderer*(client: var IPCClient): FerusRenderer {.inline.} =
  FerusRenderer(ipc: client)
