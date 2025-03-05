## Some utilities
import std/[importutils]
import pkg/[pixie, vmath, ferusgfx]

privateAccess(TextNode)

proc newTextNode*(
    content: string,
    pos: Vec2,
    dimensions: Vec2,
    font: Font,
    fontSize: float32,
    color: Color,
): TextNode =
  # TODO: forward this to upstream ferusgfx
  when defined(ferusgfxDrawDamagedRegions):
    var paint = newPaint(SolidPaint)
    paint.opacity = 0.5f
    paint.color = color(1, 0, 0, 0.5)

  font.paint.color = color

  result = TextNode(
    textContent: content,
    position: pos,
    font: font,
    bounds: rect(pos.x, pos.y, dimensions.x, dimensions.y),
    config: (needsRedraw: true),
  )

  when defined(ferusgfxDrawDamagedRegions):
    result.damageImage = newImage(result.bounds.w.int32, result.bounds.y.int32)
    result.damageImage.fill(paint)

  compute result
