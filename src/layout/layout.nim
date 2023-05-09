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
    if obj.type.name is RenderText:
      layoutEngine.renderer.drawText(
        obj.content, obj.pos, obj.dimensions, obj.font, surface
      )

proc calculateLayout*(layoutEngine: LayoutEngine) =
  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  layoutEngine.layout.add(
    newRenderText(
      "", font, (w: 40f, h: 40f), (x: 120f, y: 800f)  
    )
  )

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(dom: dom, 
               renderer: renderer, 
               fontManager: newFontManager(), 
               layout: @[])
