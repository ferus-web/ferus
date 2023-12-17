#[
 Base class for creating simple parsers quickly

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#

type
 EOFDefect* = Defect
 BaseConsumer* = proc(c: char): bool
 BaseParser* = ref object of RootObj
  idx*: int
  source*: string

proc eof*(parser: BaseParser): bool {.inline.} =
 parser.idx >= parser.source.len

proc peek*(parser: BaseParser): char {.inline.} =
 echo parser.source[parser.idx+1]
 if parser.eof():
   raise newException(EOFDefect, "Attempt to read beyond end of file.")

 parser.source[parser.idx+1]

proc consume*(parser: BaseParser): char {.inline.} =
 if parser.eof():
  raise newException(EOFDefect, "Attempt to read beyond end of file.")

 inc parser.idx
 echo parser.source[parser.idx]
 parser.source[parser.idx]

proc consumeWhile*(parser: BaseParser, fn: BaseConsumer): string =
 var res = ""

 while not parser.eof() and fn(parser.peek()):
  res = res & parser.consume()

 res