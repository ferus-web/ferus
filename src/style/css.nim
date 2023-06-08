#[
  CSS parser
  Ported from https://github.com/mbrubeck/robinson/blob/master/src/css.rs

  This code is licensed under the MIT license
  
  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import butterfly, csstypes, algorithm, sugar, strutils

type
  Selector* = ref object of RootObj
    tagName*: string
    id*: string
    class*: string

  Declaration* = ref object of RootObj
    name*: string
    value*: auto # string, float32, CSSPixel, CSSColor

  Rule* = ref object of RootObj
    selectors*: seq[Selector]
    declarations*: seq[Declaration]

  Stylesheet* = ref object of RootObj
    rules*: seq[Rule]

  Specificity* = tuple[a, b, c: uint]
  
  Parser* = ref object of RootObj
    idx*: int
    source*: string

proc specificity*(selector: Selector): Specificity {.inline.} =
  (
    a: selector.id.len.uint,
    b: selector.class.len.uint,
    c: selector.tagName.len.uint
  )

proc consumeChar*(parser: Parser): char =
  result = parser.source[parser.idx]
  inc parser.idx

proc nextChar*(parser: Parser): char =
  parser.source[parser.idx]

proc eof*(parser: Parser): bool =
  parser.idx >= parser.source.len

proc consumeWhile*(parser: Parser, conditional: proc(c: char): bool): string =
  var res = ""

  while not parser.eof() and conditional(parser.nextChar()):
    res = res & parser.nextChar()

  res

proc consumeWhitespace*(parser: Parser) =
  discard parser.consumeWhile(
    (c: char) => c == ' '
  )

proc validIdentifierChar(c: char): bool {.inline.} =
  if c.toLowerAscii() in {'a'..'z'} or c in {'0'..'9'} or c == '-' or c == '_':
    return true

  return false

proc parseHexPair*(parser: Parser): uint8 =
  let s = parser.source[parser.idx..parser.idx+2]
  parser.idx += 2

  parseUint(s)

proc parseColor*(parser: Parser): CSSColor =
  assert parser.consumeChar() == '#'
  newCSSColor(
    parser.parseHexPair(),
    parser.parseHexPair(),
    parser.parseHexPair(),
    parser.parseHexPair()
  )

proc parseIdentifier*(parser: Parser): string =
  parser.consumeWhile(
    (c: char) => validIdentifierChar(c)
  )

proc isPx*(parser: Parser): bool =
  case parser.parseIdentifier().toLowerAscii():
    of "px": return true
    else: return false

proc parseF(c: char): bool {.inline.} =
  if c in {'0'..'9'} or c == '.':
    true
  false

proc parseFloat*(parser: Parser): float =
  let s = parser.consumeWhile(
    (c: char) => parseF(c)
  )
  parseFloat(s)

proc parseValue*(parser: Parser): Butterfly =
  var bfly: Butterfly
  if parser.nextChar() in {'0'..'9'}:
    bfly = newButterfly("")
  return bfly

proc parseSimpleSelector*()
