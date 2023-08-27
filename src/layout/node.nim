#[
 Layout node

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import aabb, chronicles, mode

const BLOCK_ELEMENTS = [
    "html", "body", "article", "section", "nav", "aside",
    "h1", "h2", "h3", "h4", "h5", "h6", "hgroup", "header",
    "footer", "address", "p", "hr", "pre", "blockquote",
    "ol", "ul", "menu", "li", "dl", "dt", "dd", "figure",
    "figcaption", "main", "div", "table", "form", "fieldset",
    "legend", "details", "summary"
]

type
    LayoutNodeType* = enum
      lntText
      lntElem

    LayoutNode* = ref object of RootObj
      # Layout ID, used by LayoutArena
      id*: uint64

      # AABB
      aabb*: AABB

      # WARNING: these can optionally be left to be nil, so use them with sanity checks provided!
      # Namely, nodeHasPrevious() and nodeHasNext()
      # Failure to do so will result in unintended behaviours, most likely a segmentation fault.

      # Previous node
      previous*: LayoutNode

      # Parent node
      parent*: LayoutNode

      # Children nodes
      children*: seq[LayoutNode]

      # Next node
      next*: LayoutNode

      # Node type
      nType*: LayoutNodeType

proc nodeHasPrevious*(layoutNode: LayoutNode): bool =
  layoutNode.previous != nil

proc nodeHasNext*(layoutNode: LayoutNode): bool =
  layoutNode.next != nil

proc getLayoutMode*(node: LayoutNode): LayoutMode =
  if node.nType == lntText:
    return lmInline
  else:
    if node.children.len > 0:
      for child in node.children:
        if child.nType == lntElem:
          return lmBlock
        else:
          return lmInline
    else:
      return lmBlock
