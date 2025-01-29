import std/[logging, options]
import pkg/[vmath]
import ../components/parsers/html/document

type
  LayoutMode* {.pure.} = enum
    Default
    AllPossibleLineBreaks
    OnlyRequiredLineBreaks

  PaintPhase* {.pure.} = enum
    Background
    Border
    Foreground
    FocusOutline
    Overlay

  HitTestResultInternalPosition* = enum
    None
    Before
    Inside
    After

  HitTestResult* = object
    node*: ref Node
    indexInNode*: int = 0
    internalPosition*: HitTestResultInternalPosition = None

  HitTestType* {.pure.} = enum
    Exact
    TextCursor

  NodeWithStyle* = object of Node

  NodeWithStyleAndBoxModelMetrics* = object of NodeWithStyle

  Box* = object of NodeWithStyleAndBoxModelMetrics

  BlockBox* = object of Box

  Node* = object of RootObj
    domNode*: Option[HTMLElement]
    document*: HTMLDocument
    containingBox*: BlockBox
