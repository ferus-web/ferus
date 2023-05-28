#[
  The Document Object Model for Ferus

  This code is licensed under the MIT license
]#

import std/[tables, marshal]

import ferushtml

type DOM* = ref object of RootObj
  document*: Document
  style*: TableRef[string, TableRef[string, Butterfly]]

proc serialize*(dom: DOM): string =
  $$dom

proc getDocument*(dom: DOM): Document =
  dom.document

proc push*(dom: DOM, elem: HTMLElement) =
  dom.document.root.push(elem)

proc newDOM*(document: Document): DOM =
    DOM(document: document, style: newTable[string, TableRef[string, Butterfly]]())
