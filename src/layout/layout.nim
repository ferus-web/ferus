import ../dom/dom, ../renderer/[render, primitives, fontmanager],
       label, element, chronicles, tables

type
  LayoutEngine* = ref object of RootObj
    dom*: DOM
    renderer*: Renderer

    fontManager: FontManager
    layoutTree*: seq[LayoutElement]

proc draw*(layoutEngine: LayoutEngine, surface: RenderImage) {.inline.} =
  for drawable in layoutEngine.layoutTree:
    drawable.draw(surface, (x: 4f, y: 4f))

proc calculate*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Clearing display list and layout tree"
  layoutEngine.layoutTree.reset()

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  layoutEngine.layoutTree.add(
    newLabel(
      "HELLO",
      layoutEngine.renderer,
      layoutEngine.fontManager
    )
  )

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(
    dom: dom, renderer: renderer, layoutTree: @[], 
    fontManager: newFontManager()
  )
