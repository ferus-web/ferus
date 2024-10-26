## Layout processor
## Copyright (C) 2024 Trayambak Rai and Ferus Authors

import std/[strutils, tables, logging, options]
import vmath, bumpy, pixie, pixie/fonts
import ./box
import ../parsers/html/document
import ../shared/sugar
import ferus_ipc/[client/prelude, shared]
import pretty

const
  PARA_BREAK_PADDING = 14
  LEADING = 2

type
  Layout* = object
    cursor*: Vec2
    ipc*: IPCClient
    width*: int
    
    isLastBoxFinalized*: bool = false
    boxes*: seq[Box]
    viewport*: Rect
    text*: string
    font*: Font

    document*: HTMLDocument

var
  WordLengths: Table[string, int]
  WordHeights: Table[string, int]

proc getWordLength*(layout: var Layout, word: string): int =
  var length: int

  if not WordLengths.contains(word):
    layout.text = word
    length = layout.font.layoutBounds(word).x.int
    WordLengths[word] = length
    
    debug "layout: computed layout width for text \"" & word & "\": " & $length
  else:
    length = WordLengths[word]

    debug "layout: retrieved cached layout width for text \"" & word & "\": " & $length

  length

proc getWordHeight*(layout: var Layout, word: string): int =
  var height: int

  if not WordHeights.contains(word):
    layout.text = word
    height = layout.font.layoutBounds(word).y.int
    WordHeights[word] = height

    debug "layout: computed layout height for text \"" & word & "\": " & $height
  else:
    height = WordLengths[word]

    debug "layout: retrieved cached layout height for text \"" & word & "\": " & $height

  height

proc newLayout*(ipc: IPCClient, font: Font): Layout {.inline.} =
  debug "layout: create layout processor"
  var layout = Layout(font: font, ipc: ipc)

  layout.cursor.reset()
  layout.boxes.reset()
  
  if not WordLengths.contains(" "):
    let bounds = layout.font.layoutBounds(" ")
    WordLengths[" "] = bounds.x.int
    WordHeights[" "] = bounds.y.int
  
  layout

proc getMaxHeight*(layout: Layout): int =
  var height = 0

  for box in layout.boxes:
    if (box.pos.y.int + box.height) > height:
      height = box.pos.y.int + box.height.int

  height

#[ proc pushRemainingChildren*(children: seq[Node], list: var seq[seq[Node]]) =
  if children.len < 1:
    debug "layout: pushRemainingChildren(): children.len < 1"
    list &= @[]
  else:
    let restChildren = children[1 ..< children.len]
    debug "layout: pushRemainingChildren(): pushing " & $restChildren.len & " elements"

    list &= restChildren
]#

proc addText*(layout: var Layout, text: string, fontSize: float32) =
  for word in text.splitLines():
    layout.font.size = fontSize

    let
      width = layout.getWordLength(word)
      height = layout.getWordHeight(word)

    layout.boxes &=
      TextBox(
        text: word,
        pos: layout.cursor,
        width: width,
        height: height,
        fontSize: fontSize
      )

    layout.cursor = vec2(layout.cursor.x + width.float, layout.cursor.y)
    if layout.cursor.x >= layout.width.float:
      layout.cursor = vec2(0f, layout.cursor.y + height.float)

proc addBreak*(layout: var Layout) =
  layout.cursor = vec2(0, layout.cursor.y + 4) # FIXME: this is not how linebreaks work!

proc addHeading*(layout: var Layout, text: string, level: uint = 1) =
  layout.addText(
    text, case level
    of 1: 32f
    of 2: 28f
    of 3: 24f
    of 4: 18f
    of 5: 16f
    else: raise newException(ValueError, "addHeading given invalid range for level: " & $level); 0f
  )
  layout.addBreak()

proc addImage*(layout: var Layout, content: string) =
  let image: Option[Image] = 
    try:
      some decodeImage(content)
    except PixieError as exc:
      error "An error occured whilst decoding image: " & exc.msg
      none(Image)

  if not *image:
    warn "Image box will not be processed as the image has failed to load."
    return

  layout.boxes &=
    ImageBox(
      image: &image,
      content: content,
      pos: layout.cursor,
      width: (&image).width,
      height: (&image).height
    )

  layout.cursor = vec2(layout.cursor.x + (&image).width.float32, layout.cursor.y)
  if layout.cursor.x >= layout.width.float:
    layout.cursor = vec2(0f, layout.cursor.y + (&image).height.float32)

proc constructFromElem*(layout: var Layout, elem: HTMLElement) =
  case elem.tag
  of TAG_P, TAG_B, TAG_SPAN, TAG_STRONG, TAG_LI, TAG_A, TAG_DIV: # FIXME: bold stuff
    if not *elem.text:
      warn "layout: <" & $elem.tag & "> element does not contain any text data, ignoring it."
      return
    
    let text = &elem.text
    layout.addText(text, 14f)
  of TAG_H1:
    if not *elem.text:
      warn "layout: <h1> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 1)
  of TAG_H2:
    if not *elem.text:
      warn "layout: <h2> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 2)
  of TAG_H3:
    if not *elem.text:
      warn "layout: <h3> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 3)
  of TAG_H4:
    if not *elem.text:
      warn "layout: <h4> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 4)
  of TAG_H5:
    if not *elem.text:
      warn "layout: <h5> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 5)
  of TAG_H6:
    if not *elem.text:
      warn "layout: <h6> element does not contain any text data, ignoring it."
      return

    let text = &elem.text
    layout.addHeading(text, 6)
  of TAG_BR:
    layout.addBreak()
  of TAG_IMG:
    let src = elem.attribute("src")

    if not *src:
      warn "layout: <img> element does not contain `src` attribute, ignoring it."
      return
    
    # ask the master to ask the network process for our tab to load an image
    let image = layout.ipc.requestDataTransfer(
      ResourceRequired, DataLocation(kind: DataLocationKind.WebRequest, url: &src)
    )
    
    if *image:
      info (&image).data
      layout.addImage((&image).data)
  else:
    warn "layout: unhandled tag: " & $elem.tag

  for child in elem.children:
    layout.constructFromElem(child)

proc constructFromDocument*(layout: var Layout, document: HTMLDocument) =
  layout.boxes.reset()
  layout.cursor.reset()

  layout.document = document
  
  let head = document.elems[0].children[0]
  let body = document.elems[0].children[1]

  for elem in body.children:
    layout.constructFromElem(elem)

  #[ while true:
    if node of Text:
      layout.addString(Text(node).data)
    
    if node.childList.len > 0:
      node = node.childList[0]
      pushRemainingChildren(node.childList, remainingChildren)
    else:
      while remainingChildren[0].len == 0:
        discard pop remainingChildren

        if remainingChildren.len < 1:
          break

      if remainingChildren.len < 1:
        break

      let currChildren = remainingChildren[0]
      discard pop remainingChildren

      node = currChildren[0]
      pushRemainingChildren(currChildren, remainingChildren) ]#

proc update*(layout: var Layout) =
  if layout.document != nil:
    layout.constructFromDocument(layout.document)
  else:
    warn "Cannot re-calculate layout if document == NULL!"

export bumpy
