<<<<<<< HEAD
#[
  AABB implementation
]#
type AABB* = ref object of RootObj
  x*: int32
  y*: int32
  w*: int32
  h*: int32

proc getLeft*(aabb: AABB): int32 =
  aabb.x

proc getRight*(aabb: AABB): int32 =
  aabb.x + aabb.w

proc getBottom*(aabb: AABB): int32 =
  aabb.y

proc getTop*(aabb: AABB): int32 =
  aabb.y + aabb.h

proc colliding*(bb1, bb2: AABB): bool =
=======
type AABB* = ref object of RootObj
  x*: int
  y*: int
  w*: int
  h*: int

# collision testing
proc `@`*(bb1, bb2: AABB): bool {.inline.} =
>>>>>>> 5576c29 ((fix) some stuff)
  bb1.x < bb2.x + bb2.w and
  bb1.x + bb1.w > bb2.x and
  bb1.y < bb2.y + bb2.h and
  bb1.y + bb1.h > bb2.y
<<<<<<< HEAD

proc newAABB*(x, y, w, h: int32 = 0): AABB =
  AABB(x: x, y: y, w: w, h: h)
=======
>>>>>>> 5576c29 ((fix) some stuff)
