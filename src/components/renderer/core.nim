import std/[options, strutils, tables, importutils, logging]
import ferusgfx, ferus_ipc/client/prelude
import opengl, pretty
import ../shared/sugar
import ../parsers/html/document
import ../layout/[box, processor]

when defined(ferusUseGlfw):
  import glfw
else:
  import windy

type FerusRenderer* = ref object
  window*: Window
  ipc*: IPCClient
  scene*: Scene

  needsNewContent*: bool = true

  layout*: Layout

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

  # privateAccess renderer.scene.camera.typeof
  # renderer.ipc.debug $renderer.scene.camera.delta

proc close*(renderer: FerusRenderer) {.inline.} =
  info "Closing renderer."

  when defined(ferusUseGlfw):
    destroy renderer.window
    glfw.terminate()

proc setWindowTitle*(renderer: FerusRenderer, title: string) {.inline.} =
  info "Setting window title to \"" & title & "\""
  renderer.window.title = title

proc paintLayout*(renderer: FerusRenderer) =
  var displayList = newDisplayList(addr renderer.scene)
  displayList.doClearAll = true
  
  var start, ending: Vec2
  for i, box in renderer.layout.boxes:
    if i == 0 or box.pos.y < start.y:
      `=destroy`(start)
      wasMoved(start)
      start = vec2(box.pos.x, box.pos.y - (box.height.float + 32)) # FIXME: more precise document start detection
    elif box.pos.y > ending.y:
      `=destroy`(ending)
      wasMoved(ending)
      ending = deepCopy(box.pos)

    if box of TextBox:
      let textBox = TextBox(box)
      if textBox.width < 1 or textBox.height < 1:
        continue

      displayList.add(
        newTextNode(textBox.text, textBox.pos, vec2(textBox.width.float, textBox.height.float), renderer.scene.fontManager.getTypeface("Default"), textBox.fontSize)
      )
    elif box of ImageBox:
      let imageBox = ImageBox(box)
      if imageBox.width < 1 or imageBox.height < 1:
        continue

      let node = newImageNodeFromMemory(imageBox.content, imageBox.pos) # FIXME: this is wasteful! We already have the image loaded into memory!

      displayList.add(
        node
      )
  
  renderer.scene.camera.setBoundaries(start, ending)
  displayList.commit()

proc renderDocument*(renderer: FerusRenderer, document: HTMLDocument) =
  info "Rendering HTML document - calculating layout"
    
  var layout = newLayout(renderer.ipc, renderer.scene.fontManager.get("Default"))

  if *document.head():
    for child in &document.head():
      if child.tag == TAG_TITLE:
        if *child.text:
          info "Setting document title: " & &child.text
          renderer.setWindowTitle(&child.text & " — Ferus")
        else:
          warn "<title> tag has no text content!"
  else:
    info "Document has no <head>"

  layout.constructFromDocument(document)
  renderer.layout = move(layout)

  renderer.paintLayout()

proc resize*(renderer: FerusRenderer, dims: tuple[w, h: int32]) {.inline.} =
  info "Resizing renderer viewport to $1x$2" % [$dims.w, $dims.h]
  let casted = (w: dims.w.int, h: dims.h.int)
  renderer.scene.onResize(casted)
  #renderer.layout.update()
  #renderer.paintLayout()

proc initialize*(renderer: FerusRenderer) {.inline.} =
  info "Initializing renderer."
  
  when defined(ferusUseGlfw):
    glfw.initialize()

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
      "Initializing", ivec2(1280, 720)
    )
    window.makeContextCurrent()
  
  renderer.window = window
  renderer.scene = newScene(1280, 1080)

  when defined(ferusUseGlfw):
    window.windowSizeCb = proc(_: Window, size: tuple[w, h: int32]) =
      renderer.resize(size)

    window.scrollCb = proc(_: Window, offset: tuple[x, y: float64]) =
      # debug "Scrolling (offset: " & $offset & ")"
      let vector = vec2(offset.x, offset.y)
      renderer.scene.onScroll(vector)

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
