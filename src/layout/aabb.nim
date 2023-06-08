#[
  Axis aligned bounding boxes implementation

  This code is licensed under the MIT license

  Authors:

  xTrayambak (xtrayambak at gmail dot com)
]#
import ../renderer/primitives, pixie

type AABB* = ref object of RootObj
  x*: int
  y*: int
  w*: int
  h*: int

proc debugDraw*(aabb: AABB, surface: RenderImage) {.inline.} =
  let context = newContext(surface.img)
  context.fillStyle = rgba(255, 0, 0, 255)
  context.fillRect(
    rect(
      vec2(aabb.x.float32, aabb.y.float32),
      vec2(aabb.w.float32, aabb.h.float32)
    )
  )

proc collidesWith*(aabb1, aabb2: AABB): bool {.inline.} =
  aabb1.x < aabb2.x + aabb2.w and
  aabb1.x + aabb1.w > aabb2.x and
  aabb1.y < aabb2.y + aabb2.h and
  aabb1.h + aabb1.y > aabb2.y

proc newAABB*(x, y, w, h: int): AABB {.inline.} = AABB(x: x , y: y, w: w, h: h)
