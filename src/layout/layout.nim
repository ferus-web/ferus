import ../dom/dom, ../renderer/[render, primitives, fontmanager],
       label, element, aabb, chronicles, tables

const LAYOUT_TILE_SIZE = 64 # px
type
  LayoutEngine* = ref object of RootObj
    dom*: DOM
    renderer*: Renderer

    fontManager: FontManager
    layoutTree*: seq[LayoutElement]

    tiles*: seq[
      tuple[
        x, y: uint
      ]
    ]

proc getPos*(layoutEngine: LayoutEngine, 
             currNode: LayoutElement,
             lastNode: LayoutElement
            ): tuple[x, y: int] {.inline.} =
  echo "lastNode's bottom: " & $(lastNode.box.aabb.getBottom() + 8)
  echo "currNode's height: " & $(currNode.box.aabb.h)
  echo "currNode's top: " & $(currNode.box.aabb.getTop())
  echo "lastNode's top: " & $(lastNode.box.aabb.getTop())
  (
    x: 0,#lastNode.box.aabb.getRight() + 8,
    y: lastNode.box.aabb.getBottom() + 8
  )

proc draw*(layoutEngine: LayoutEngine, 
          surface: RenderImage) {.inline.} =
  var last: LayoutElement
  
  for drawable in layoutEngine.layoutTree:
    if not last.isNil:
      let pos = layoutEngine.getPos(drawable, last)

      drawable.box.aabb.x = pos.x
      drawable.box.aabb.y = pos.y

      drawable.draw(
        surface, 
        (
          x: pos.x.float32,
          y: pos.y.float32
        )
      )
    else:
      drawable.box.aabb.x = 0
      drawable.box.aabb.y = 0
      drawable.draw(
        surface, 
        (
          x: 0f, 
          y: 0f
        )
      )
    
    last = drawable

proc calculate*(layoutEngine: LayoutEngine) =
  info "[src/layout/layout.nim] Clearing display list and layout tree"
  layoutEngine.layoutTree.reset()

  var font = layoutEngine.fontManager.loadFont("Default", "../data/IBMPlexSans-Regular.ttf")
  layoutEngine.layoutTree.add(
    newLabel(
      "HELLO WORLD!",
      layoutEngine.renderer,
      layoutEngine.fontManager
    )
  )
  #[layoutEngine.layoutTree.add(
    newLabel(
      "HOWDY PLANET EARTH!",
      layoutEngine.renderer,
      layoutEngine.fontManager
    )
  )]#
  layoutEngine.layoutTree.add(
    newLabel(
      "GREETINGS, PLANET WITH LIFE!",
      layoutEngine.renderer,
      layoutEngine.fontManager
    )
  )

proc newLayoutEngine*(dom: DOM, 
                      renderer: Renderer
                      ): LayoutEngine {.inline.} =
  var tiles: seq[tuple[x, y: uint]] = @[]

  LayoutEngine(
    dom: dom, renderer: renderer, layoutTree: @[], 
    fontManager: newFontManager(), tiles: tiles
  )
