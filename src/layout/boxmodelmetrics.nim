#[
  Box model metrics

  This code is licensed under the MIT license

  Authors: xTrayambak (xTrayambak at gmail dot com)
]#
import ../style/csstypes

type 
  PixelBox* = ref object of RootObj
    top*: CSSFloat
    right*: CSSFloat
    bottom*: CSSFloat
    left*: CSSFloat

  BoxModelMetrics* = ref object of RootObj
    margin*: PixelBox
    padding*: PixelBox
    border*: PixelBox
    inset*: PixelBox

proc marginBox*(boxMetrics: BoxModelMetrics): PixelBox {.inline.} =
  let
    margin = boxMetrics.margin
    border = boxMetrics.border
    padding = boxMetrics.padding

  PixelBox(
    top: margin.top + border.top + padding.top,
    right: margin.right + border.right + padding.right,
    bottom: margin.bottom + border.right + padding.right,
    left: margin.left + border.left + padding.left
  )

proc paddingBox*(boxMetrics: BoxModelMetrics): PixelBox {.inline.} =
  PixelBox(
    top: boxMetrics.padding.top, right: boxMetrics.padding.right, 
    bottom: boxMetrics.padding.bottom, left: boxMetrics.padding.left
  )

proc borderBox*(boxMetrics: BoxModelMetrics): PixelBox {.inline.} =
  PixelBox(
    top: boxMetrics.border.top + boxMetrics.padding.top,
    right: boxMetrics.border.right + boxMetrics.padding.right,
    bottom: boxMetrics.border.bottom + boxMetrics.padding.bottom,
    left: boxMetrics.border.left + boxMetrics.padding.left,
  )
