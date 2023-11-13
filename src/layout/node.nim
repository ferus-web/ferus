#[
 Layout node

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
<<<<<<< HEAD
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
=======
import std/[strutils, htmlparser, options], pixie,
       aabb

type
  LayoutNodeKind* = enum
    lnkGeneric
    lnkGenerated
    lnkIframe
    lnkMedia
    lnkCanvas
    lnkSvg
    lnkInlineAbsHypothetical
    lnkInlineAbs
    lnkScannedText
    lnkTable
    lnkTableCell
    lnkTableColumn
    lnkTableRow
    lnkTableWrapper
    lnkMulticol
    lnkMulticolColumn
    lnkTruncatedFragment

  LayoutType* = enum
    ltDefault
    ltBlock
    ltInline

  LayoutNode* = ref object of RootObj
    prev*: LayoutNode
    next*: LayoutNode
    kind*: LayoutNodeKind

    htmlTag*: HTMLTag

    precomputedLayoutType: LayoutType

    children*: seq[LayoutNode]

    aabb*: AABB

proc `x=`*(node: LayoutNode, x: int) =
  node.aabb.x = x

proc `y=`*(node: LayoutNode, y: int) =
  node.aabb.y = y

proc `w=`*(node: LayoutNode, w: int) =
  node.aabb.w = w

proc `h=`*(node: LayoutNode, h: int) =
  node.aabb.h = h

proc getLayoutType*(node: LayoutNode): LayoutType =
  if node.precomputedLayoutType != ltDefault:
    return node.precomputedLayoutType
  
  if node.htmlTag in BlockTags:
    node.precomputedLayoutType = ltBlock
    return ltBlock
  elif node.htmlTag in InlineTags:
    node.precomputedLayoutType = ltInline
    return ltInline

proc getPrev*(node: LayoutNode): Option[LayoutNode] =
  if node.prev != nil:
    return some(node.prev)

proc getNext*(node: LayoutNode): Option[LayoutNode] =
  if node.next != nil:
    return some(node.next)

method draw*(layoutNode: LayoutNode, context: Context) {.base.} =
 return

proc newLayoutNode*(
  tag: string, 
  kind: LayoutNodeKind = lnkGeneric,
  aabb: AABB
): LayoutNode =

  let htmlTag = case tag.toLowerAscii()
  of "p": tagP
  of "h1": tagH1
  of "h2": tagH2
  of "h3": tagH3
  of "h4": tagH4
  of "h5": tagH5
  of "h6": tagH6
  of "a": tagA
  of "abbr": tagAbbr
  of "acronym": tagAcronym
  of "applet": tagApplet
  of "area": tagArea
  of "article": tagArticle
  else: tagUnknown # TODO: add the rest of em
  
  LayoutNode(htmlTag: htmlTag, children: @[], aabb: aabb)
>>>>>>> 5576c29 ((fix) some stuff)
