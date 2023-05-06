#[
  The Document Object Model for Ferus

  This code is licensed under the MIT license
]#

import std/tables

import ../butterfly
import ../parsers/html/[element]
import document

type DOM* = ref object of RootObj
  document*: Document
  style*: TableRef[string, TableRef[string, Butterfly]]

proc getDocument*(dom: DOM): HTMLElement =
  dom.document

proc newDOM*: DOM =
  DOM(document: newDocument(), style: newTable[string, TableRef[string, Butterfly]]())
