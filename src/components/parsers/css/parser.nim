import std/[strutils, tables, options]
import stylus/[parser, shared, tokenizer], results
import pkg/pretty
import ./[types, selector_parser, anb, keywords, units]
import ../../shared/sugar

type CSSParser* = ref object
  state*: Parser

proc newCSSParser*(source: string): CSSParser {.inline.} =
  CSSParser(state: newParser(newParserInput source))

proc eof*(parser: CSSParser): bool {.inline, noSideEffect, gcsafe.} =
  parser.state.input.tokenizer.isEof

proc reconsume*(parser: CSSParser, state: ParserState) {.inline.} =
  parser.state.reset(state)

proc parseValueFromToken*(parser: CSSParser, token: Token): CSSValue =
  case token.kind
  of tkFunction:
    assert(false, "Nested CSS functions not supported yet")
  of tkDimension:
    if token.unit in Units:
      return dimension(token.dValue, &token.unit.parseUnit())
    else:
      # FIXME: this is a bug in stylus. Numbers are marked as dimensions
      if !token.dIntVal:
        return decimal(token.dValue)
      else:
        return number(&token.dIntVal)
  of tkIdent:
    return str(token.ident)
  else:
    print token
    unreachable

proc parseFunction*(parser: CSSParser, nameTok: Token): Option[CSSValue] {.inline.} =
  let name = nameTok.fnName
  var args: seq[CSSValue]

  if !parser.state.expectParenBlock():
    return

  while not parser.eof:
    let next = &parser.state.next()
    if next.kind == tkComma:
      continue

    if next.kind == tkCloseParen:
      break

    let value = parser.parseValueFromToken(next)
    args &= value

  parser.state.atStartOf = none(BlockType)

  some(function(name, move(args)))

proc parseRule*(parser: CSSParser): Option[Rule] =
  let ident = parser.state.expectIdent()

  if !ident:
    return

  let colon = parser.state.expectColon()

  if !colon:
    return

  let ovalue = parser.state.next()

  if !ovalue:
    return

  let value = &ovalue

  var parsedValue: CSSValue

  case value.kind
  of tkFunction:
    parsedValue = &parser.parseFunction(value)
  of tkDimension, tkIdent:
    parsedValue = parser.parseValueFromToken(value)
  else:
    unreachable

  if !parser.state.expectSemicolon():
    return

  return some(Rule(key: (&ident), value: parsedValue))

proc onEncounterIdentifier*(parser: CSSParser, ident: Token): Stylesheet =
  if !parser.state.expectCurlyBracketBlock():
    return

  var rules: seq[Rule]
  let name = ident.ident

  while not parser.eof:
    let rule = parser.parseRule()
    var parsed = &rule
    parsed.selector = tagSelector(name)

    rules &= parsed

    let copied = parser.state.deepCopy()
    if parser.state.expectCloseCurlyBracket.isOk:
      break
    else:
      parser.state = copied

  rules

proc consumeRules*(parser: CSSParser): Stylesheet =
  var stylesheet: Stylesheet

  while not parser.eof:
    let initToken = parser.state.next()

    if !initToken:
      let err = initToken.error()
      if err.kind == bpEndOfInput:
        break

    let init = &initToken
    case init.kind
    of tkIdent:
      stylesheet &= parser.onEncounterIdentifier(init)
    else:
      discard

  stylesheet
