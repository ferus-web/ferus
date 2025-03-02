## Yoga-based layout engine
import std/[logging, tables]
import pkg/[pixie, vmath]
import ../../bindings/yoga
import ../../components/parsers/html/document
import ../../components/shared/sugar
import ../../components/ipc/[client/prelude, shared]

type
  Style* = object
    margin*: float

  ProcessedData* = object
    position*: Vec2
    dimensions*: Vec2

  LayoutNode* = object
    parent*: ptr LayoutNode
    children*: seq[LayoutNode]
    element*: HTMLElement
    attached*: YGNodeRef
    font*: Font

    style*: Style
    processed*: ProcessedData

  Layout* = object
    ipc*: IPCClient
    tree*: LayoutNode           ## Pass 1: Raw node
    viewport*: Vec2
    font*: Font

proc constructFromElem*(layout: var Layout, elem: HTMLElement): LayoutNode =
  var node: LayoutNode
  node.element = elem
  
  for i, _ in elem.children:
    var childNode = layout.constructFromElem(elem.children[i])
    childNode.parent = node.addr
    node.children.add(childNode)

  ensureMove(node)

proc constructTree*(layout: var Layout, document: HTMLDocument) =
  var body = document.body()
  assert(*body)

  layout.tree = layout.constructFromElem(&body)

  # print layout.tree

proc traverse*(layout: Layout, node: var LayoutNode) =
  var yogaNode = newYGNode()
  node.attached = yogaNode
  node.font = layout.font

  template blockElem =
    node.attached.setWidthPercent(100) # Take up 100% of the parent's width - force all new content to start from the next line.
    node.attached.setFlexDirection(YGFlexDirectionColumn)
    node.attached.setAlignSelf(YGAlignStretch)

  case node.element.tag
  of TAG_P:
    let text = &node.element.text()
    node.font.size = 24
    let bounds = node.font.layoutBounds(text)
    
    blockElem
    node.attached.setHeight(bounds.y)
    node.processed.dimensions = bounds
  of { TAG_H1, TAG_H2, TAG_H3, TAG_H4, TAG_H5, TAG_H6 }:
    let text = &node.element.text()
    node.font.size = 32
    let bounds = node.font.layoutBounds(text)
    
    blockElem
    node.attached.setHeight(bounds.y)
    node.processed.dimensions = bounds
  else: discard

  for i, _ in node.children:
    layout.traverse(node.children[i])
    node.attached.insertChild(node.children[i].attached, cast[ptr YGNode](node.attached)[].childCount())

proc traversePass2*(node: var LayoutNode) =
  node.processed.position = vec2(
    cast[ptr YGNode](node.attached)[].getLeft(),
    cast[ptr YGNode](node.attached)[].getTop()
  )
  node.processed.dimensions = vec2(
    cast[ptr YGNode](node.attached)[].getWidth(),
    cast[ptr YGNode](node.attached)[].getHeight()
  )

  for i, _ in node.children:
    node.children[i].traversePass2()

proc finalizeLayout*(layout: var Layout) =
  layout.traverse(layout.tree) # Attach a Yoga node to all the nodes in the layout tree
  layout.tree.attached.setWidth(layout.viewport.x)
  layout.tree.attached.setHeight(layout.viewport.y)
  layout.tree.attached.calculateLayout(
    layout.viewport.x, layout.viewport.y,
    YGDirectionLTR
  ) # Compute layout of the root

  # Perform another traversal, setting the computed position attribute
  layout.tree.traversePass2()
