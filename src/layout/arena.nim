#[
  LayoutNode arena

  This is just a LayoutNode that hosts all LayoutNode(s)
]#
import node, mode, chronicles

type LayoutArena* = ref object of LayoutNode

proc blockLayout*(arena: LayoutArena, parent: LayoutNode = LayoutNode()) =
  info "[src/layout/arena.nim] Beginning block layout!"
  
  # there is no way that a parent can't have either a prev or next node
  let parentIsDummy = not parent.nodeHasPrevious() and not parent.nodeHasNext()

  var 
    prev: LayoutNode
    node: LayoutNode = arena.children[idx]
  let mode = getLayoutMode(node)

  if mode == lmBlock:
    for child in node.children:
      if parentIsDummy:
        if prev != nil:
          arena.blockLayout(child, arena, prev)
        else:
          arena.blockLayout(child, arena)
      else:
        if prev != nil:
          arena.blockLayout(child, parent, prev)
        else:
          arena.blockLayout(child, parent)

  info "[src/layout/arena.nim] Layout is done. Hopefully it layouts correctly. *Hopefully.*"
