#[
  Dump an element and it's children

  This code is licensed under the MIT license
]#

import strutils, strformat
import element

proc dump*(elem: HTMLElement, 
           rounds: int = 0, discardInternals: bool = true): string =
  var
    str = ""
    rounds = rounds
    textContent: string

  if elem.textContent.len > 0 and not isEmptyOrWhitespace(elem.textContent):
    textContent = elem.textContent
  else:
    textContent = ""
  
  if discardInternals and elem.tagName != "ferusRootIgnore":
    let elemInfo = fmt"[id: {elem.tagName}; numchildren: {elem.children.len}; textContent: {textContent}]"
    var tabs = ""

    for x in 0..rounds:
      tabs = tabs & "\t"
  
    str = str & tabs & elemInfo & "\n"

  if elem.children.len > 0:
    for child in elem.children:
      inc rounds
      str = str & dump(child, rounds, discardInternals)
  str
