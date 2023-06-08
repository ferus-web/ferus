#[
  Layout box object

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import node, aabb, ../style/csstypes

type
  LineBoxFragmentCoordinate* = ref object of RootObj
    lineBoxIndex*: int
    fragmentIndex*: int

  Box* = ref object of LayoutNodeWithBoxModelMetrics
    aabb*: AABB

proc newBox*(aabb: AABB): Box {.inline.} =
  Box(aabb: aabb)
