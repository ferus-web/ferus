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

proc getTop*(aabb: AABB): int {.inline.} =
  aabb.y + aabb.h

proc getBottom*(aabb: AABB): int {.inline.} =
  aabb.y

proc getLeft*(aabb: AABB): int {.inline.} =
  aabb.x

proc getRight*(aabb: AABB): int {.inline.} =
  aabb.x + aabb.w

proc debugDraw*(aabb: AABB, surface: RenderImage) =
  let context = newContext(surface.img)
  context.strokeStyle = "#FF5C00"
  context.lineWidth = 5

  # Top left to top right
  context.strokeSegment(
    segment(
      vec2(aabb.getLeft().float32, aabb.getTop().float32),
      vec2(aabb.getRight().float32, aabb.getTop().float32)
    )
  )

  # Bottom left to bottom right
  context.strokeSegment(
    segment(
      vec2(aabb.getLeft().float32, aabb.getBottom().float32),
      vec2(aabb.getRight().float32, aabb.getBottom().float32)
    )
  )

  # Top left to bottom left
  context.strokeSegment(
    segment(
      vec2(aabb.getLeft().float32, aabb.getTop().float32),
      vec2(aabb.getLeft().float32, aabb.getBottom().float32)
    )
  )

  # Top right to bottom right
  context.strokeSegment(
    segment(
      vec2(aabb.getRight().float32, aabb.getTop().float32),
      vec2(aabb.getRight().float32, aabb.getBottom().float32)
    )
  )

proc collidesWith*(aabb1, aabb2: AABB): bool {.inline.} =
  aabb1.x < aabb2.x + aabb2.w and
  aabb1.x + aabb1.w > aabb2.x and
  aabb1.y < aabb2.y + aabb2.h and
  aabb1.h + aabb1.y > aabb2.y

proc newAABB*(x, y, w, h: int): AABB {.inline.} = 
  AABB(
    x: x, 
    y: y, 
    w: w, 
    h: h
  )
