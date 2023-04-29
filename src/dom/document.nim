#[
  A HTML document.

  This code is licensed under the MIT license
]#

import chronicles, times, os, tables
import ../parsers/html/element
import ../parsers/html/html

type
  DocumentReadyState* = enum
    drLoading, drInteractive, drComplete

  Document* = ref object of HTMLElement
    body*: HTMLElement
    head*: HTMLElement

    parser*: Parser
    readyState*: DocumentReadyState

    title*: string
    dir*: string

proc createElement*(document: Document, localName: string, options: TableRef[string, string])

proc parseHTML(document: Document, input: string) =
  var startTime = cpuTime()

  document.root = parse(document.parser, input, document.root)
  
  info "[src/dom/document.nim] parseHTML(): completed parsing HTML!", timeTaken=cpuTime() - startTime

proc parseFromFile(document: Document, fileName: string) =
  info "[src/parsers/dom.nim] parseFromFile(): fetching file"
  assert fileExists(fileName)

  var contents = readFile(fileName)

  parseHTML(document, contents)

proc newDocument*: Document =
  var parser = newParser()
  Document(parser: parser, 
           body: newHTMLElement("root", "", parser), 
           readyState: DocumentReadyState.drLoading)
