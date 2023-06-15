#[
  Text label

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import ../renderer/[primitives, render, fontmanager], 
       box, node, aabb, element, 
       pixie,
       std/[strutils]

type Label* = ref object of LayoutElement

method draw*(label: Label, surface: RenderImage, pos: tuple[x, y: float32]) =
  #label.box.aabb.x = label.primitive.pos.x.int
  #label.box.aabb.y = label.primitive.pos.y.int

  label.box.aabb.debugDraw(surface)
  label.renderer.drawText(
    label.primitive.content, 
    pos, label.primitive.dimensions,
    label.primitive.font, surface
  )

proc computeSize(textContent: string, font: Font): int {.inline.} =
  (font.size.int * textContent.len)

proc newLabel*(textContent: string, renderer: Renderer, 
              fontMgr: FontManager, sizeInc: int = 0): Label =
  let
    font = fontMgr.getFont("Default")
    size = computeSize(textContent, font) + sizeInc
    prim = newRenderText(
      textContent,
      font,
      (w: size.float32, h: 64f), (x: 0f, y: 0f)
    )

  Label(
    renderer: renderer,
    primitive: prim,
    node: newLayoutNode(
      true, false, true, false, ssNone 
    ),
    box: newBox(
      newAABB(
        prim.pos.x.int, prim.pos.y.int, 
        (font.size.int * textContent.len), font.size.int
      )
    ),
    breaksLine: false
  )
