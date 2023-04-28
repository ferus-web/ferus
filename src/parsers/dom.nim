#[
  The Document Object Model for Ferus

  This code is licensed under the MIT license
]#

import chronicles
import std/[times, os]
import html/[html, element]

type DOM* = ref object of RootObj
  parser*: Parser
  root*: HTMLElement

proc parseHTML*(dom: DOM, input: string, doClearHierarchy: bool) =
  var startTime = cpuTime()
  info "[src/parsers/dom.nim] parseHTML(): start!"
  if doClearHierarchy:
    info "[src/parsers/dom.nim] parseHTML(): clearing DOM node hierarchy"
    dom.root.children.reset()

  dom.root = parse(dom.parser, input, dom.root)

  info "[src/parsers/dom.nim] parseHTML(): completed parsing of HTML! DOM is now populated with parsed HTML source to nodes", endTime = $(cpuTime() - startTime)

proc getDocument*(dom: DOM): HTMLElement =
  dom.root

proc parseFromFile*(dom: DOM, fileName: string, doClearHierarchy: bool) =
  info "[src/parsers/dom.nim] parseFromFile(): fetching file"
  assert fileExists(fileName)

  var contents = readFile(fileName)

  parseHTML(dom, contents, doClearHierarchy)

proc newDOM*: DOM =
  var parser = newParser()

  DOM(parser: parser, root: newHTMLElement("root", "", parser))
