#[
  Base layout element (text, images, etc.)

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import box, node, chronicles, ../renderer/[render, primitives]

type
  LayoutElement* = ref object of RootObj
    box*: Box
    node*: LayoutNode
    primitive*: RenderPrimitive
    renderer*: Renderer
    breaksLine*: bool

method draw*(layoutElement: LayoutElement, 
             surface: RenderImage, 
             pos: tuple[x, y: float32]
            ) {.base.} =
  return

proc newLayoutElement*(box: Box, 
                       node: LayoutNode, 
                       primitive: RenderPrimitive,
                       renderer: Renderer, 
                       breaksLine: bool = true
                      ): LayoutElement {.inline.} =
  LayoutElement(box: box, node: node, primitive: primitive, 
                renderer: renderer, breaksLine: breaksLine)