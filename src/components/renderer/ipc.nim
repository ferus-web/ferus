import std/base64

import ferus_ipc/shared, vmath
from ferusgfx import Scene
import ferusgfx/displaylist

import ../parsers/html/document

type
  DrawableKind* = enum
    TextNode
    ImageNode
    GIFNode

  Drawable* = ref object
    position*: Vec2
    case kind*: DrawableKind
    of TextNode:
      content*: string
      font*: string ## this isnt the path!
    of ImageNode:
      imgContent*: string
    of GIFNode:
      gifContent*: string

  RendererMutationPacket* = ref object
    kind: FerusMagic = feRendererMutation
    list*: IPCDisplayList

  RendererLoadFontPacket* = ref object
    kind: FerusMagic = feRendererLoadFont
    name*, content*, format*: string
  
  RendererSetWindowTitle* = ref object
    kind: FerusMagic = feRendererSetWindowTitle
    title*: string
  
  RendererRenderDocument* = ref object
    kind: FerusMagic = feRendererRenderDocument
    document*: HTMLDocument

  RendererGotoURL* = ref object
    kind: FerusMagic = feRendererGotoURL
    url*: string

  IPCDisplayList* = GDisplayList[Drawable] ## IPC display list

# omitting pointer to scene provided by GDisplayList (server-side)
proc dumpHook*(s: var string, v: ptr Scene) {.inline.} =
  s = "null"

# client side
proc parseHook*(s: string, i: int, v2: ptr Scene) {.inline.} =
  discard

proc newTextNode*(content: string, position: Vec2, font: string): Drawable {.inline.} =
  Drawable(
    kind: TextNode,
    content: content.encode(safe = true),
    position: position,
    font: font
  )

proc newImageNode*(
  path: string,
  position: Vec2
): Drawable {.inline.} =
  Drawable(
    kind: ImageNode,
    imgContent: path.readFile().encode(safe = true),
    position: position
  )

proc newGIFNode*(
  path: string,
  position: Vec2
): Drawable {.inline.} =
  Drawable(
    kind: GIFNode,
    gifContent: path.readFile().encode(safe = true),
    position: position
  )

proc newDisplayList*(clearAll: bool = false): IPCDisplayList {.inline.} =
  IPCDisplayList(doClearAll: clearAll)

export vmath, displaylist
