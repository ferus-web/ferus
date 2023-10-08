#[
 Layout node

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import pixie

type LayoutNode* = ref object of RootObj
 parent*: LayoutNode

method draw*(layoutNode: LayoutNode, context: Context) {.base.} =
 return
