import std/[strutils, options]
import stylus/[parser, shared, tokenizer], results
import ./[types, selector_parser, anb]
import ../../shared/sugar

type CSSParser* = ref object
  state*: Parser

proc newCSSParser*(source: string): CSSParser {.inline.} =
  CSSParser(
    state: newParser(
      newParserInput source
    )
  )

proc eof*(parser: CSSParser): bool {.inline, noSideEffect, gcsafe.} =
  parser.state.input.tokenizer.isEof

proc reconsume*(parser: CSSParser, state: ParserState) {.inline.} =
  parser.state.reset(state)

proc reconsume*(parser: CSSParser) {.inline.} =
  dec parser.state.input.tokenizer.pos

proc consumeFunction*(parser: CSSParser): ComponentValue =
  let fn = parser.state.input.tokenizer.nextToken()

  Function(
    name: fn.fnName
  )

proc consumeComponentValue*(parser: CSSParser): ComponentValue

proc consumeSimpleBlock*(parser: CSSParser): SimpleBlock =
  parser.reconsume()
  let 
    t = parser.state.next().get()
    ending = case t.kind
    of tkCurlyBracketBlock:
      tkCloseCurlyBracket
    of tkParenBlock:
      tkCloseParen
    of tkSquareBracketBlock:
      tkCloseSquareBracket
    else: t.kind

  result = SimpleBlock(
    token: t
  )

  while not parser.eof:
    let t = parser.state.next()

    if !t:
      break

    if t.get().kind == ending:
      return result
    else:
      if t.get().kind in [tkCurlyBracketBlock, tkSquareBracketBlock, tkParenBlock]:
        result.value.add(parser.consumeSimpleBlock())
      else:
        parser.reconsume()
        result.value.add(parser.consumeComponentValue())

proc consumeComponentValue*(parser: CSSParser): ComponentValue =
  if @(parser.state.expectCurlyBracketBlock()) or
    @(parser.state.expectParenBlock()) or
    @(parser.state.expectSquareBracketBlock()):
    return parser.consumeSimpleBlock()
  elif @(parser.state.expectFunction()):
    parser.reconsume()
    return parser.consumeFunction()

  ComponentValue()

proc consumeDeclaration*(parser: CSSParser, name: string): Option[Declaration] =
  if !parser.state.expectColon():
    return
  
  var decl = Declaration(name: name)

  while not parser.eof:
    decl.value.add(parser.consumeComponentValue())

proc consumeQualifiedRule*(parser: CSSParser): Option[QualifiedRule] =
  var qRule = QualifiedRule()

  while not parser.eof:
    let t = parser.state.next()

    if @t and &t is SimpleBlock and (&t).kind == tkCurlyBracketBlock:
      qRule.oblock = SimpleBlock(token: &t, value: @[])
      return some(qRule)
    elif @t and (&t).kind == tkCurlyBracketBlock:
      qRule.oblock = parser.consumeSimpleBlock()
      return some(qRule)
    else:
      parser.reconsume()
      qRule.prelude &=
        parser.consumeComponentValue()

  none(QualifiedRule)

proc consumeAtRule*(parser: CSSParser): AtRule =
  let t = parser.input.next()

  result = AtRule(name: t.value)

proc consumeListOfRules*(parser: CSSParser, topLevel: bool = false): seq[Rule] =
  while not parser.eof:
    let beforeNext = parser.state.state()
    let t = parser.state.next().get()

    case t.kind
    of tkCDC, tkCDO:
      if topLevel: continue
      else:
        parser.reconsume(beforeNext)
        
        let qRule = parser.consumeQualifiedRule()

        if *qRule:
          result.add(&qRule)
    of tkAtKeyword:
      parser.reconsume(beforeNext)
      result.add(parser.consumeAtRule())
    else:
      parser.reconsume(beforeNext)
      let qRule = parser.consumeQualifiedRule()
      if *qRule:
        result.add(&qRule)
