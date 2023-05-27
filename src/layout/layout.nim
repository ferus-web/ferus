import ../renderer/render,
       ../renderer/primitives,
       ../dom/dom,
       ../parsers/css/css,
       ../renderer/fontmanager,
       pixie,
       std/typetraits,
       chronicles, ferushtml

let
  width = 64f #px
  height = 64f #px

type LayoutEngine* = ref object of RootObj
  dom*: DOM
  renderer*: Renderer
  fontManager*: FontManager
  layout*: seq[RenderPrimitive]

  cx*: float
  cy*: float

proc processLayout*(layoutEngine: LayoutEngine, surface: RenderImage) =
  for obj in layoutEngine.layout:
    if obj.content.len > 1:
      # TODO(xTrayambak): this is a horrible way to this, we're making literal assumptions here
      # on the basis of if the text content has a greater length than 1 or not. This is stupid.
      layoutEngine.renderer.drawText(
        obj.content, obj.pos, obj.dimensions, obj.font, surface
      )
    else:
      # TODO(xTrayambak): add code to handle images
      warn "[src/layout/layout.nim] Unimplemented render primitive inside layout engine stack -- ignoring it for now. This should never happen, file an issue."

proc placeElement*(layoutEngine: LayoutEngine, elem: HTMLElement, font: Font, ignore: bool = false) =
  layoutEngine.cx = layoutEngine.cx + width + 0.1
  layoutEngine.cy = layoutEngine.cy + height + 0.1
  
  if not ignore:
    layoutEngine.layout.add(
      newRenderText(
        elem.textContent, font, (w: width, h: height),
        (x: layoutEngine.cx.float32, y: layoutEngine.cy.float32)
      )
    )
  
  for child in elem.children:
    layoutEngine.placeElement(child, font, false)

proc calculateLayout*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Calculating layout!"

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  echo layoutEngine.dom.document.root.dump()

  layoutEngine.placeElement(layoutEngine.dom.document.body, font, true)

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(dom: dom, 
               renderer: renderer, 
               fontManager: newFontManager(), 
               layout: @[])
