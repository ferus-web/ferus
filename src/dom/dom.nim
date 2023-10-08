#[
  The Document Object Model for Ferus

  This code is licensed under the MIT license

  Authors:

  xTrayambak (xtrayambak at gmail dot com)
]#

import std/[tables, marshal]

import ../html/dombuilder

type DOM* = ref object of RootObj
  document*: Document
  # style*: TableRef[string, TableRef[string, HTMLButterfly]]

proc serialize*(dom: DOM): string =
  $$dom

proc getDocument*(dom: DOM): Document {.inline.} =
  dom.document

#[proc push*(dom: DOM, elem: Element) {.inline.} =
  dom.document.root.push(elem)]#

proc newDOM*(document: Document): DOM {.inline.} =
    DOM(document: document)
