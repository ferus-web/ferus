import std/[logging, options]
import pkg/[vmath]
import ../components/parsers/html/document

type
  NodeWithStyle* = object of Node

  NodeWithStyleAndBoxModelMetrics* = object of NodeWithStyle

  Box* = object of NodeWithStyleAndBoxModelMetrics

  BlockBox* = object of Box
    bounds*: Rect

  ProcessedData* = object
    position*: Vec2

  Node* = object of RootObj
    domNode*: Option[HTMLElement]
    document*: ref HTMLDocument
    containingBox*: BlockBox
    
    processed*: ProcessedData ## Set by the layout engine
