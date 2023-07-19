import ../dom/dom, ../renderer/[render, primitives, fontmanager],
       label, node, handler/handler, chronicles,
       pixie, std/tables, cssgrid, pretty

type
  LayoutEngine* = ref object of RootObj
    dom*: DOM
    renderer*: Renderer

    fontManager: FontManager
    layoutTree*: seq[LayoutNode]

    parent*: LayoutNode
    gridTemplate*: GridTemplate

proc draw*(layoutEngine: LayoutEngine,
          surface: RenderImage) {.inline.} =
  for layoutNode in layoutEngine.layoutTree:
    layoutNode.draw(newContext(surface.img))

proc calculate*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Clearing display list and layout tree"
  layoutEngine.layoutTree.reset()

  var font = layoutEngine.fontManager.loadFont(
    "Default",
    "../data/fonts/IBMPlexSans-Regular.ttf"
  )
  parseDOM(
    layoutEngine.dom,
    layoutEngine.renderer,
    layoutEngine.fontManager,
    layoutEngine.layoutTree,
    layoutEngine.parent
  )

  parseGridTemplateColumns layoutEngine.gridTemplate, 0'ux 32'ux
  parseGridTemplateRows layoutEngine.gridTemplate, 33'ux 33'ux
  layoutEngine.gridTemplate.justifyItems = CxStretch

  info "[src/layout/layout.nim] Computing layout"
  layoutEngine.gridTemplate.computeNodeLayout(
    layoutEngine.parent,
    layoutEngine.layoutTree
  )

proc newLayoutEngine*(dom: DOM,
                      renderer: Renderer
                      ): LayoutEngine {.inline.} =
  info "[src/layout/layout.nim] Initializing layout engine -- creating grid template and root layout node."
  var
    gridTemplate = newGridTemplate()
    # gridTemplate.autoFlow = grRow

    parent = LayoutNode(
      box: uiBox(
        0, 0,
        renderer.width.float32,
        renderer.height.float32
      )
    )

  LayoutEngine(
    dom: dom, renderer: renderer, layoutTree: @[], 
    fontManager: newFontManager(),
    parent: parent, gridTemplate: gridTemplate
  )
