import std/options, node, aabb, vmath

type LayoutProcessor* = ref object of RootObj
  nodes*: seq[LayoutNode]

  width*: int32
  height*: int32

proc setup*(layout: LayoutProcessor) =
  var prev: LayoutNode
  for node in layout.nodes:
    if prev != nil:
      prev.next = node

    node.prev = prev

proc getPosFor*(layout: LayoutProcessor, node: LayoutNode): IVec2 =
  if node.prev == nil:
    return ivec2(0, 0)

  if node.getLayoutType() == ltBlock:
    let prev = node.getPrev()
    
    assert prev.isSome

    let
      prevX = prev.get().aabb.x
      prevY = prev.get().aabb.y

    return ivec2(
      0'i32, (prevY + 1).int32
    )

  return ivec2(0, 0)

proc calculate*(layout: LayoutProcessor) =
  for node in layout.nodes:
    let pos = layout.getPosFor(node)

    node.x = pos.x
    node.y = pos.y
