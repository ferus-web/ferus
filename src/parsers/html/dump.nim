#[
  Dump DOM info

  This code is licensed under the MIT license
]#

import strutils, strformat
import ../../dom/document

proc dumpDocument*(document: Document): string =
  var 
    i = -1
    output = ""
