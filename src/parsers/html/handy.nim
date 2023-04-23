#[
  Handy utilities for debugging the DOM in the console
]#
import strformat
import ../dom
import element


proc recursiveDumpChild*(child: HTMLElement, t: int): string =
  var output = ""

  let tabs = "\t"
  for tt in 0..t:
    tabs = tabs & "\t"

  let cData = fmt"{tabs}ID: {}\n{tabs}TextContent: {}\n"
  output = output & cData

  for subchild in child.children:
    output = output & recursiveDumpChild(subchild, t + 1)

  output

proc dumpDOM*(dom: DOM): string =
  var output = ""

  for rootsChildren in dom.root.children:
    let tabs = "\t"
    let cData = fmt"{tabs}ID: {}\n{tabs}TextContent: {}\n"
    output = output & cData

    for rcChildren in rootsChildren.children:
      output = output & recursiveDumpChild(rcChildren, 1)


  output
