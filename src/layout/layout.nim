import ../renderer/render,
       ../renderer/primitives,
       ../dom/dom,
       ../parsers/css/css,
       ../renderer/fontmanager,
       pixie,
       std/typetraits,
       chronicles

type LayoutEngine* = ref object of RootObj
  dom*: DOM
  renderer*: Renderer
  fontManager*: FontManager
  layout*: seq[RenderPrimitive]

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


proc calculateLayout*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Calculating layout!"

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  layoutEngine.layout.add(
    newRenderText(
      "This is definitely a layout.", font, (w: 40f, h: 40f), (x: 120f, y: 800f)  
    )
  )

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(dom: dom, 
               renderer: renderer, 
               fontManager: newFontManager(), 
               layout: @[])
