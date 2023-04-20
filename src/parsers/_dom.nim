import std/tables
import chronicles

#[
  A Node object.
]#
type Node* = ref object of RootObj
  id*: string
  attributes*: TableRef[string, string]
  children*: seq[Node]

#[
  A DOM object inherited from a Node class.
]#
type DOM* = ref object of Node

#[
  Push a Node into a DOM's hierarchy (this should preferably only be used once for <html> tag)
]#
proc push*(dom: DOM, node: Node) =
  dom.children.add(node)

#[
  Push a Node into another Node's children hierarchy.
]#
proc push*(node: Node, child: Node) =
  node.children.add(child)

#[
  Go through a subchild, append its attributes to the string from earlier and if more children are found, recurse itself.
  Contrary to the function name, this is NOT recursive. It only tries until 32768 passes and then gives up.
  I have not tested this well enough, this looks atrocious and IS atrocious. I am late for my tuition!
]#
proc recursiveDumpChild*(output: string, child: Node, passes: int): string =
  let passes = passes + 1
  var output = output
  var nextescapes = "\t"

  for x in 1..passes:
    nextescapes = nextescapes & "\t"

  if passes >= 32768:
    warn "[ferus/parsers/dom.nim] recursiveDumpSubchild(): passes is greater than maximum threshold (32768)! Abort!"
    return output

  output = output & "\n\t" & nextescapes & "ID: " & child.id 

  for name, attr in child.attributes:
    output = output & "\n" & nextescapes & "\t\t" & name & " -- " & attr
  
  if child.children.len != 0:
    for subchild in child.children:
      output = output & recursiveDumpChild("", subchild, passes)
  
  output

#[
  Go through a DOM, get all tags, their attributes, and their children and their attributes recursively.
  Then, return a neat string of information.
]#
proc dump*(dom: DOM): string =
  var output = ""
  var htmlTag = dom.children[0]
  var data: seq[string] = @[]

  if htmlTag.id != "html":
    warn "[ferus/parsers/dom.nim] Root tag inside DOM hierarchy is not <html>, things could go veeery wrong!", malformedRoot=htmlTag.id

  for child in htmlTag.children:
    var rdc = recursiveDumpChild(output, child, 0)
    data.add(rdc)

  for d in data:
    output = output & d
  output = "[DOM DUMP]\n" & output & "\n[END]"
  output

#[
  Convenience function for newTable[string, string]()
]#
proc newAttributeSet*: TableRef[string, string] =
  newTable[string, string]()

#[
  Instantiate a new Node
]#
proc newNode*(id: string, attributes: TableRef[string, string], children: seq[Node]): Node =
  Node(id: id, attributes: attributes, children: children)

#[
  Instantiate a new DOM
]#
proc newDOM*: DOM =
  DOM(children: @[])
