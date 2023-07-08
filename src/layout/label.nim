#[
  Text label

  This code is licensed under the MIT license

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import ../renderer/[primitives, render, fontmanager], 
       node, cssgrid,
       pixie,
       std/[strutils]

type Label* = ref object of LayoutNode
  textContent*: string
  font*: string

method draw*(label: Label, context: Context) =
  context.font = label.font
  #label.context.fillColor(rgba(255, 255, 255, 255))
  echo "X: " & $label.box.Rect.x
  echo "Y: " & $label.box.Rect.y
  context.fillText(label.textContent, 
    label.box.Rect.x, 
    label.box.Rect.y
  )

proc computeSize(textContent: string): tuple[rows, columns: int] =
  (rows: 1, columns: 1)

proc newLabel*(textContent: string, parent: GridNode, font: string): Label =
  Label(
    textContent: textContent,
    parent: parent,
    font: font
  )
