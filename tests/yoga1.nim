import bindings/yoga
import pretty

echo YGAlignAuto
var root = newYGNode()
root.setFlexDirection(YGFLexDirectionRow)
root.setWidth(100f)
root.setHeight(100f)

var node = newYGNode()
node.setWidthPercent(100)
node.insertChild(node, 0)

root.calculateLayout(1280, 720, YGDirectionLTR)
