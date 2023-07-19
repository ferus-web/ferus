#[
 Layout node

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import cssgrid, pixie

type LayoutNode* = ref object of RootObj
 box*: UIBox
 parent*: LayoutNode
 gridItem*: GridItem

method draw*(layoutNode: LayoutNode, context: Context) {.base.} =
 return

proc getRect*(layoutNode: LayoutNode): Rect =
 layoutNode.box.Rect

proc newLayoutNode*(parent: GridNode): LayoutNode =
 LayoutNode(parent: parent, box: parent.box, gridItem: newGridItem())