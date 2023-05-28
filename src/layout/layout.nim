import ../renderer/render,
       ../renderer/primitives,
       ../dom/dom,
       ../parsers/css/css,
       ../renderer/fontmanager,
       handler/html/box,
       pixie,
       std/typetraits,
       std/tables,
       constants,
       jsony, os,
       chronicles, ferushtml

let
  width = 64f #px
  height = 64f #px

type
  Layout* = TableRef[tuple[x, y: int], Box]
  LayoutEngine* = ref object of RootObj
    dom*: DOM
    renderer*: Renderer
    fontManager*: FontManager
    stack*: seq[RenderPrimitive]

    layout*: Layout

proc processLayout*(layoutEngine: LayoutEngine, surface: RenderImage) =
  for obj in layoutEngine.stack:
    if obj.content.len > 1:
      # TODO(xTrayambak): this is a horrible way to this, we're making literal assumptions here
      # on the basis of if the text content has a greater length than 1 or not. This is stupid.
      layoutEngine.renderer.drawText(
        obj.content, obj.pos, obj.dimensions, obj.font, surface
      )
    else:
      # TODO(xTrayambak): add code to handle images
      warn "[src/layout/layout.nim] Unimplemented render primitive inside layout engine stack -- ignoring it for now. This should never happen, file an issue."

proc processBody(layoutEngine: LayoutEngine, font: Font) =
  info "[src/layout/layout.nim] Processing body!"
  for elem in layoutEngine.dom.document.root.findChildByTag("html").findChildByTag("body").children:
    if elem.tag == "p1":
      when defined(ferusUseVerboseLogging):
        info "[src/layout/layout.nim] Handling <p1>"

      let 
        w = DIMENSIONS["p1"]["x"].float32
        h = DIMENSIONS["p1"]["y"].float32

      layoutEngine.stack.add(
        newRenderText(
          elem.textContent, font,
          (w: w, h: h), (x: 0f, y: 0f)
        )
      )
    elif elem.tag == "p2":
      when defined(ferusUseVerboseLogging):
        info "[src/layout/layout.nim] Handling <p2>"

      let
        w = DIMENSIONS["p2"]["x"].float32
        h = DIMENSIONS["p2"]["y"].float32

      layoutEngine.stack.add(
        newRenderText(
          elem.textContent, font,
          (w: w, h: h), (x: 0f, y: 0f)
        )
      )
    elif elem.tag == "p3":
      when defined(ferusUseVerboseLogging):
        info "[src/layout/layout.nim] Handling <p3>"

      let
        w = DIMENSIONS["p3"]["x"].float32
        h = DIMENSIONS["p3"]["y"].float32

      layoutEngine.stack.add(
        newRenderText(
          elem.textContent, font,
          (w: w, h: h), (x: 0f, y: 0f)
        )
      )
    elif elem.tag == "p4":
      when defined(ferusUseVerboseLogging):
        info "[src/layout/layout.nim] Handling <p4>"

      let
        w = DIMENSIONS["p4"]["x"].float32
        h = DIMENSIONS["p4"]["y"].float32

      layoutEngine.stack.add(
        newRenderText(
          elem.textContent, font,
          (w: w, h: h), (x: 0f, y: 0f)
        )
      )
proc calculateLayout*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Flushing stack and calculating layout!"
  layoutEngine.stack.reset()

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  echo layoutEngine.dom.document.root.dump()

  layoutEngine.processBody(font)

proc newLayout: Layout =
  newTable[
    tuple[x, y: int], Box
  ]()

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(dom: dom, 
               renderer: renderer, 
               fontManager: newFontManager(),
               stack: @[],
               layout: newLayout())
