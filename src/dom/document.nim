#[
  A HTML document.

  This code is licensed under the MIT license
]#

import chronicles, times, os
import ../parsers/html/element
import ../parsers/html/html

type
  DocumentReadyState* = enum
    drLoading, drInteractive, drComplete

  Document* = ref object of HTMLElement
    root*: HTMLElement
    body*: HTMLElement
    head*: HTMLElement

    htmlParser*: HTMLParser
    readyState*: DocumentReadyState

    title*: string
    dir*: string


# proc createElement*(document: Document, localName: string, options: TableRef[string, string])

proc parseHTML*(document: Document, input: string) =
  var startTime = cpuTime()

  document.root = parse(document.htmlParser, input, document.root)

  try:
    document.body = document.root.findByTagName("html").findByTagName("body")
    document.head = document.root.findByTagName("html").findByTagName("head")
  except ValueError as e:
    warn "[src/dom/document.nim] findByTagName() threw a ValueError! This means that we may be parsing bad data."
 
  info "[src/dom/document.nim] parseHTML(): completed parsing HTML!", timeTaken=cpuTime() - startTime

proc parseFromFile*(document: Document, fileName: string) =
  info "[src/parsers/dom.nim] parseFromFile(): fetching file"
  assert fileExists(fileName)

  var contents = readFile(fileName)

  parseHTML(document, contents)

proc newDocument*: Document =
  var parser = newHTMLParser()
  Document(htmlParser: parser, 
           root: newHTMLElement("ferusRootIgnore", "", parser),
           head: newHTMLElement("head", "", parser),
           body: newHTMLElement("body", "", parser), 
           readyState: DocumentReadyState.drLoading)
