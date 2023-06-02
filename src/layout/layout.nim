import ../dom/dom, ../renderer/[render, primitives, fontmanager],
       std/typetraits, chronicles

type 
  LayoutEngine* = ref object of RootObj
    dom*: DOM
    renderer*: Renderer

    displayList*: seq[RenderPrimitive]
    fontManager: FontManager
    layoutTree*: seq[int]

proc draw*(layoutEngine: LayoutEngine, surface: RenderImage) =
  return

proc calculate*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Clearing display list and layout tree"
  layoutEngine.displayList.reset()
  layoutEngine.layoutTree.reset()

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")

  layoutEngine.displayList.add(
    newRenderText(
      "Layout engine attempt #2", font, (w: 32f, h: 32f),
      (x: 0f, y: 0f)
    )
  )

proc newLayoutEngine*(dom: DOM, renderer: Renderer): LayoutEngine =
  LayoutEngine(dom: dom, renderer: renderer, displayList: @[], layoutTree: @[], 
  fontManager: newFontManager())
