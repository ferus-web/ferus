import std/[options, strutils, tables, sugar, importutils, logging, sets]
import pkg/[ferusgfx, opengl, pretty, chroma, jsony, vmath, bumpy]
import ../shared/sugar
import ./ipc
import ../../components/parsers/html/document
import ../../components/parsers/css/[parser]
import ../../components/layout/[processor]
import ../../components/web/legacy_color
import ../../components/ipc/client/prelude

import glfw

type
  CursorManager* = object
    normal*, hand*, forbidden*: Cursor

    hovered*: bool

  FerusRenderer* = ref object
    window*: Window
    cursorMgr*: CursorManager
    ipc*: IPCClient
    scene*: Scene

    needsNewContent*: bool = true
    viewport*: Vec2
    document*: HTMLDocument

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

  glfw.pollEvents()

  # privateAccess renderer.scene.camera.typeof
  # renderer.ipc.debug $renderer.scene.camera.delta

proc close*(renderer: FerusRenderer) {.inline.} =
  info "Closing renderer."

  destroy renderer.window
  glfw.terminate()

proc setWindowTitle*(renderer: FerusRenderer, title: string) {.inline.} =
  info "Setting window title to \"" & title & "\""
  renderer.window.title = title

proc onAnchorClick*(renderer: FerusRenderer, location: string) =
  info "Anchor clicked that points to: " & location
  renderer.ipc.send(RendererGotoURL(url: location))

  renderer.scene.camera.reset()

proc buildDisplayList*(
    renderer: FerusRenderer, list: var DisplayList, node: LayoutNode
) =
  assert node.element != nil,
    "BUG: Layout node does not have a HTML element attached to it!"

  if node.processed.dimensions.x > 0 and node.processed.dimensions.y > 0:
    case node.element.tag
    of {TAG_P, TAG_STRONG}:
      list.add(
        newTextNode(
          &node.element.text,
          node.processed.position,
          node.processed.dimensions,
          renderer.scene.fontManager.getTypeface("Default"),
          node.processed.fontSize,
          color = node.processed.color.asColor(),
        )
      )
    of {TAG_H1, TAG_H2, TAG_H3, TAG_H4, TAG_H5, TAG_H6}:
      list.add(
        newTextNode(
          &node.element.text,
          node.processed.position,
          node.processed.dimensions,
          renderer.scene.fontManager.getTypeface("Default"),
          node.processed.fontSize,
          color = node.processed.color.asColor()
        )
      )
    of TAG_A:
      list.add(
        newTextNode(
          &node.element.text,
          node.processed.position,
          node.processed.dimensions,
          renderer.scene.fontManager.getTypeface("Default"),
          node.processed.fontSize,
          color = node.processed.color.asColor(),
        )
      )

      # Add a touch interest node
      var pList = list.addr

      capture node:
        pList[].add(
          newTouchInterestNode(
            rect(node.processed.position, node.processed.dimensions),
            proc(_: seq[string], mouse: MouseClick) =
              if mouse != MouseClick.Left:
                return

              let href = node.element.attribute("href")
              failCond *href

              renderer.ipc.send(
                RendererGotoURL(url: &href)
              ),

            proc(_: seq[string]) =
              echo "hovered, yippee."
              renderer.cursorMgr.hovered = true
          )
        )
    else:
      discard

    for child in node.children:
      renderer.buildDisplayList(list, child)

proc paintLayout*(renderer: FerusRenderer) =
  var displayList = newDisplayList(addr renderer.scene)
  displayList.doClearAll = true

  var start, ending: Vec2
  renderer.buildDisplayList(displayList, renderer.layout.tree)

  #[ for i, box in renderer.layout.boxes:
    if i == 0 or box.pos.y < start.y:
      `=destroy`(start)
      wasMoved(start)
      start = vec2(box.pos.x, box.pos.y - (box.height.float + 32))
        # FIXME: more precise document start detection
    elif box.pos.y > ending.y:
      `=destroy`(ending)
      wasMoved(ending)
      ending = deepCopy(box.pos)

    if box of TextBox:
      var textBox = TextBox(box)
      if textBox.width < 1 or textBox.height < 1:
        continue

      displayList.add(
        newTextNode(
          textBox.text,
          textBox.pos,
          vec2(textBox.width.float, textBox.height.float),
          renderer.scene.fontManager.getTypeface("Default"),
          textBox.fontSize,
          color = (
            if *textBox.href:
              color(0, 0, 1, 1)
            else:
              color(0, 0, 0, 1)
          ),
        )
      )

      if *textBox.href:
        displayList.add(
          newTouchInterestNode(
            rect(textBox.pos, vec2(textBox.width.float, textBox.height.float)),
            clickCb = (
              proc(tags: seq[string], button: MouseClick) =
                if button == MouseClick.Left:
                  renderer.onAnchorClick(tags[0])
            ),
            hoverCb = nil, # (proc(tags: seq[string]) =
            tags = @[&textBox.href],
          )
        )
    elif box of ImageBox:
      let imageBox = ImageBox(box)
      if imageBox.width < 1 or imageBox.height < 1:
        continue

      var node = newImageNodeFromMemory(imageBox.content, imageBox.pos)
        # FIXME: this is wasteful! We already have the image loaded into memory!
      node.image = imageBox.image

      displayList.add(node)
  ]#

  ending = renderer.viewport
  renderer.scene.camera.setBoundaries(start, ending)
  displayList.commit()

proc handleBackgroundColor*(renderer: FerusRenderer, bgcolor: string) =
  debug "Handling `bgcolor` attribute on <body> tag: " & bgcolor
  # TODO: we don't do this with styles yet, make sure to port this over
  # when we have a working styling engine!

  let color = parseLegacyColorValue(bgcolor)
  if *color:
    let sample = rgb(&color)
    renderer.scene.setBackgroundColor(rgba(sample.r, sample.g, sample.b, 255))

proc shouldClose*(renderer: FerusRenderer): bool =
  renderer.window.shouldClose

proc renderDocument*(renderer: FerusRenderer, document: HTMLDocument) =
  info "Rendering HTML document - calculating layout"
  if renderer.cursorMgr.hovered:
    renderer.window.cursor = renderer.cursorMgr.hand
  else:
    renderer.window.cursor = renderer.cursorMgr.normal

  var layout = Layout(
    ipc: renderer.ipc,
    font: renderer.scene.fontManager.get("Default"),
    viewport: renderer.viewport,
  )
  assert(layout.font != nil)

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

  let body = &document.body()
  if (let bgcolorO = body.attribute("bgcolor"); *bgcolorO):
    renderer.handleBackgroundColor(&bgcolorO)

  # Load our user agent CSS stylesheet.
  # It provides the basic "sane default" measurements
  layout.stylesheet &= newCSSParser(readFile("assets/user-agent.css")).consumeRules()

  # FIXME: do this in a compliant way.
  for child in body.children:
    if child.tag == TAG_STYLE:
      if !child.text:
        warn "renderer: <style> tag has no content; ignoring."
        continue

      var parser = newCSSParser(&child.text())
      layout.stylesheet &= parser.consumeRules()

  renderer.document = document
  renderer.layout = move(layout)
  renderer.layout.constructTree(document)
  renderer.layout.finalizeLayout()

  renderer.paintLayout()

proc resize*(renderer: FerusRenderer, dims: tuple[w, h: int32]) {.inline.} =
  info "Resizing renderer viewport to $1x$2" % [$dims.w, $dims.h]
  let casted = (w: dims.w.int, h: dims.h.int)
  renderer.scene.onResize(casted)
  renderer.viewport = vec2(dims.w.float, dims.h.float)

  if renderer.layout.viewport.x != renderer.viewport.x:
    # TODO: use some logic to mark nodes that need to be relayouted as "dirty"
    # currently, we're recomputing the entire page's layout upon resizing
    # which is horribly inefficient...

    if renderer.document != nil:
      renderer.layout.recalculating = true
      renderer.layout.constructTree(renderer.document)
      renderer.layout.finalizeLayout()
      renderer.paintLayout()

proc initialize*(renderer: FerusRenderer) {.inline.} =
  info "Initializing renderer."

  glfw.initialize()

  loadExtensions()

  var conf = DefaultOpenglWindowConfig
  conf.title = "Ferus"
  conf.size = (w: 1280, h: 1080)
  conf.makeContextCurrent = true
  conf.version = glv30

  var window =
    try:
      newWindow(conf)
    except GLFWError as exc:
      error "Failed to initialize GLFW window: " & exc.msg
      quit(8)

  renderer.window = window
  renderer.scene = newScene(1280, 1080)
  renderer.cursorMgr = CursorManager(
    normal: createStandardCursor(csArrow),
    hand: createStandardCursor(csHand),
    forbidden: createStandardCursor(csNotAllowed)
  )

  window.windowSizeCb = proc(_: Window, size: tuple[w, h: int32]) =
    renderer.resize(size)

  window.scrollCb = proc(_: Window, offset: tuple[x, y: float64]) =
    # debug "Scrolling (offset: " & $offset & ")"
    let vector = vec2(offset.x, offset.y)
    renderer.scene.onScroll(vector)

  window.mouseButtonCb = proc(
      _: Window, button: MouseButton, pressed: bool, mods: set[ModifierKey]
  ) =
    if button == mbLeft:
      renderer.scene.onCursorClick(pressed, MouseClick.Left)
    elif button == mbRight:
      renderer.scene.onCursorClick(pressed, MouseClick.Right)

  window.cursorPositionCb = proc(_: Window, pos: tuple[x, y: float64]) =
    renderer.cursorMgr.hovered = false
    renderer.scene.onCursorMotion(vec2(pos.x, pos.y))
    if renderer.cursorMgr.hovered:
      renderer.window.cursor = renderer.cursorMgr.hand
    else:
      renderer.window.cursor = renderer.cursorMgr.normal

  renderer.window = window

proc newFerusRenderer*(client: var IPCClient): FerusRenderer {.inline.} =
  FerusRenderer(ipc: client, viewport: vec2(1280, 1080))
