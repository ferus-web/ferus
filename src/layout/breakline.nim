#[
 <br> tag

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import box, node, aabb, element, ../renderer/[render, primitives]

type Breakline* = ref object of LayoutElement

method draw*(breakline: Breakline, surface: RenderImage, pos: tuple[x, y: float32]) =
 return

proc newBreakline*(renderer: Renderer): Breakline =
 Breakline(
  renderer: renderer,
  node: newLayoutNode(
   true, false, true, false, ssNone
  ),
  box: newBox(
   newAABB(
    0, 0,
    0, 0
   )
  ),
  breaksLine: true
 )