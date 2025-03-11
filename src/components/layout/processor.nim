## Yoga-based layout engine
import std/[logging, strutils, tables, importutils, options]
import pkg/[pixie, vmath, pretty]
import ../../bindings/yoga
import ../../components/parsers/html/document
import ../../components/parsers/css/[parser, anb, types]
import ../../components/style/[selector_engine, style_matcher, functions]
import ../../components/shared/sugar
import ../../components/ipc/[client/prelude, shared]

type
  Style* = object
    margin*: float

  ProcessedData* = object
    position*: Vec2
    dimensions*: Vec2
    fontSize*: float32
    color*: ColorRGBA

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
    tree*: LayoutNode ## Pass 1: Raw node
    viewport*: Vec2
    font*: Font
    recalculating*: bool = false
    stylesheet*: Stylesheet

func dump*(node: LayoutNode, level: uint = 1): string =
  ## Dump a layout node and its children
  var s: string
  s &=
    "<" & $node.element.tag & ", x: " & $node.processed.position.x & ", y: " &
    $node.processed.position.y & ", w: " & $node.processed.dimensions.x & ", h: " &
    $node.processed.dimensions.y & ">\n"

  for child in node.children:
    s &= ' '.repeat(level)
    s &= child.dump(level + 1)
    s &= '\n'

  s

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

  if layout.recalculating:
    layout.tree.attached.freeRecursive()

  layout.stylesheet.sortStylesheetBySpecificity()
  layout.tree = layout.constructFromElem(&body)

  # print layout.tree

proc handleWidthProperty*(
    layout: Layout,
    node: var LayoutNode,
    default: CSSValue = dimension(100, CSSUnit.Percent),
) =
  ## Handle the `width` CSS property on a node.
  let widthRule =
    if (let x = layout.stylesheet.getProperty(node.element, Property.Width); *x):
      debug "layout: node " & $node.element.tag & " has width property"
      &x
    else:
      debug "layout: node " & $node.element.tag &
        " does not have width property, defaulting to 100%"
      default

  failCond widthRule.kind == cssDimension
  case widthRule.kind
  of cssDimension:
    case widthRule.dim.unit
    of {CSSUnit.Mm, CSSUnit.In, CSSUnit.Cm, CSSUnit.Px}:
      node.attached.setWidth(widthRule.toPixels())
    of CSSUnit.Percent:
      node.attached.setWidthPercent(widthRule.dim.value)
  else:
    unreachable

proc traverse*(
    layout: Layout, prev: ptr LayoutNode, node: var LayoutNode
): bool {.discardable.} =
  var yogaNode = newYGNode()
  node.attached = yogaNode
  node.font = layout.font

  template blockElem() =
    layout.handleWidthProperty(node)
    node.attached.setFlexDirection(YGFlexDirectionRow)
    # node.attached.setAlignSelf(YGAlignStretch)
    result = false

  template inlineElem() =
    node.attached.setFlexDirection(YGFlexDirectionColumn)
    node.attached.setWidth(bounds.x)
    node.attached.setHeight(bounds.y)

    result = false

    # Get parented to the previous node, if it exists.
    #[ if prev != nil:
      echo $node.element.tag & " parented to " & $prev.element.tag
      prev.attached.insertChild(node.attached, cast[ptr YGNode](prev.attached)[].childCount())
      result = true ]#

  template applyStyle() =
    let fontSize =
      toPixels(&layout.stylesheet.getProperty(node.element, Property.FontSize))
    node.processed.fontSize = fontSize
    node.font.size = fontSize

    let textDecoration =
      layout.stylesheet.getProperty(node.element, Property.TextDecoration)

    if *textDecoration:
      let property = &textDecoration
      if property.kind == cssString:
        case property.str
        of "underline":
          node.font.underline = true
        of "line-through":
          node.font.strikethrough = true
        of "none":
          discard
        else:
          warn "layout: UNIMPLEMENTED: `text-decoration` mode: " & property.str

    let color =
      evaluateRGBXFunction(&layout.stylesheet.getProperty(node.element, Property.Color))

    failCond *color
      # FIXME: Use a more fault-tolerant approach. Currently we just skip the entire node and its children upon this basic failure.
    node.processed.color = &color

  case node.element.tag
  of TAG_P:
    let text = &node.element.text()

    applyStyle()

    let bounds = node.font.layoutBounds(text)

    node.attached.setHeight(bounds.y)
    node.processed.dimensions = bounds

    blockElem()
  of {TAG_H1, TAG_H2, TAG_H3, TAG_H4, TAG_H5, TAG_H6}:
    let text = &node.element.text()

    applyStyle()

    let bounds = node.font.layoutBounds(text)

    node.attached.setHeight(bounds.y)
    blockElem() # tell the layout engine to treat these as block elements
  of TAG_STRONG:
    let text = &node.element.text()

    applyStyle()

    let bounds = node.font.layoutBounds(text)

    inlineElem()
  of TAG_A:
    if *node.element.text:
      let text = &node.element.text()

      applyStyle()

      let bounds = node.font.layoutBounds(text)

      inlineElem()
  of TAG_BODY:
    let bounds = layout.viewport
    inlineElem()
  else:
    discard

  for i, _ in node.children:
    let inlined = layout.traverse(
      if i > 0:
        node.children[i - 1].addr
      else:
        node.addr,
      node.children[i],
    )

    if not inlined:
      node.attached.insertChild(
        node.children[i].attached, cast[ptr YGNode](node.attached)[].childCount()
      )

proc traversePass2*(node: var LayoutNode) =
  node.processed.position = vec2(
    cast[ptr YGNode](node.attached)[].getLeft(),
    cast[ptr YGNode](node.attached)[].getTop(),
  )
  node.processed.dimensions = vec2(
    cast[ptr YGNode](node.attached)[].getWidth(),
    cast[ptr YGNode](node.attached)[].getHeight(),
  )

  for i, _ in node.children:
    node.children[i].traversePass2()

proc finalizeLayout*(layout: var Layout) =
  layout.traverse(nil, layout.tree)
    # Attach a Yoga node to all the nodes in the layout tree

  layout.tree.attached.calculateLayout(
    layout.viewport.x, layout.viewport.y, YGDirectionLTR
  ) # Compute layout of the root

  # Perform another traversal, setting the computed position attribute
  layout.tree.traversePass2()
