## I love chame

#!fmt:off
import std/[options, logging, strutils, tables]
import
  pkg/[pretty, shakar], pkg/chagashi/charset, pkg/sanchar/parse/url, pkg/simdutf/base64
import ../../web/dom
#!fmt:on

type
  HTMLElement* = ref object
    tag*: TagType
    class*: seq[string]
    children*: seq[HTMLElement]
    attributes*: Table[string, string]

    text: Option[string]

  HTMLDocument* = ref object
    encoding*: Charset
    elems*: seq[HTMLElement]
    url*: URL

iterator items*(elem: HTMLElement): HTMLElement =
  for child in elem.children:
    yield child

func body*(doc: HTMLDocument): Option[HTMLElement] {.inline.} =
  if doc.elems.len < 1:
    return

  for elem in doc.elems[0]:
    if elem.tag == TAG_BODY:
      return some(elem)

func head*(doc: HTMLDocument): Option[HTMLElement] {.inline.} =
  if doc.elems.len < 1:
    return

  for elem in doc.elems[0]:
    if elem.tag == TAG_HEAD:
      return some(elem)

func findAll*(
    element: HTMLElement, tag: TagType, descend: bool = false
): seq[HTMLElement] =
  var res: seq[HTMLElement]

  for elem in element.children:
    if elem.tag == tag:
      res &= elem

    if descend:
      res &= elem.findAll(tag, descend = true)

  res

proc text*(elem: HTMLElement): Option[string] {.inline.} =
  if *elem.text:
    return some(decode(&elem.text, urlSafe = true))

proc attribute*(elem: HTMLElement, name: string): Option[string] {.inline.} =
  if name in elem.attributes:
    return some(decode(elem.attributes[name], urlSafe = true))

proc classes*(elem: HTMLElement): seq[string] {.inline.} =
  let classAttr = elem.attribute("class")
  if !classAttr:
    return

  split(&classAttr, ' ')

proc parseHTMLElement*(document: Document, element: Element): HTMLElement =
  var elem = HTMLElement()
  let tag = element.tagType()
  debug "html: tag is " & $tag
  elem.tag = tag

  for (prefix, namespace, name, value) in element.attrs:
    # we currently don't really care about the namespace
    let mappedName = document.factory.atomToStr(name)
    elem.attributes[mappedName] = encode(value, urlSafe = true)

  case tag
  of TAG_P,
      {TAG_H1 .. TAG_H6},
      TAG_TITLE,
      TAG_SCRIPT,
      TAG_B,
      TAG_SPAN,
      TAG_STRONG,
      TAG_LI,
      TAG_A,
      TAG_STYLE:
    var text: string

    for txt in element.textNodes:
      text &= txt.data

    elem.text = some(encode(text, urlSafe = true))
  else:
    discard

  for child in element.elementNodes:
    elem.children &= document.parseHTMLElement(child)

  elem

proc parseHTMLDocument*(document: Document): HTMLDocument =
  info "Turning chame HTML document into ferus compatible HTML document"
  var html = HTMLDocument()
  html.encoding = document.charset

  for elem in document.elementNodes:
    html.elems &= document.parseHTMLElement(elem)

  html

export TagType
