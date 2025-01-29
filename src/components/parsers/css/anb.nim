import results
import std/[strutils, options, sugar]
import stylus/[tokenizer, parser, shared]
import ./types

proc match(s: string, fn: proc(c: char): bool): bool {.inline.} =
  for c in s:
    if not fn(c):
      return false

  true

proc parseSignlessB*(
    parser: Parser, a: int32, bSign: int32
): Result[AnB, BasicParseError] {.inline.} =
  let rnext = parser.next()

  if rnext.isErr:
    return err(rnext.error())

  let next = get rnext

  case next.kind
  of tkNumber:
    if not next.nHasSign and next.nIntVal.isSome:
      return ok(anb(a, bSign * next.nIntVal.unsafeGet()))
  else:
    discard

  err(parser.newBasicUnexpectedTokenError(next))

proc parseNumberSaturate*(str: string): Result[int32, void] =
  var
    input = newParserInput(str)
    parserObj = newParser(input)

  let rnextwc = parserObj.nextIncludingWhitespaceAndComments()

  if rnextwc.isErr:
    return err()

  let
    nextwc = get rnextwc
    integer =
      if nextwc.kind == tkNumber and nextwc.nIntVal.isSome:
        nextwc.nIntVal.unsafeGet()
      else:
        return err()

  # FIXME: implement this
  #if not parserObj.isExhausted():
  #  return err()

  ok integer

proc parseNDashDigits*(str: string): Result[int32, void] =
  if str.len >= 3 and str[0 .. 2].toLowerAscii() == "n-" and
      str[2 .. str.len - 1].match((c) => c in {'0' .. '9'}):
    parseNumberSaturate(str[1 .. str.len - 1])
  else:
    err()

proc parseB*(input: Parser, a: int32): Result[AnB, BasicParseError] =
  let
    start = input.state()
    rnext = input.next()

  if rnext.isOk:
    let next = get rnext

    case next.kind
    of tkDelim:
      case next.delim
      of '+':
        return parseSignlessB(input, a, 1)
      of '-':
        return parseSignlessB(input, a, -1)
      else:
        discard
    of tkNumber:
      if next.nHasSign and next.nIntVal.isSome:
        return ok(anb(a, next.nIntVal.unsafeGet()))
    else:
      discard

  input.reset(start)
  ok(anb(a, 0))

proc parseNth*(input: Parser): Result[AnB, BasicParseError] =
  let next = input.next().get()

  case next.kind
  of tkNumber:
    if next.nIntVal.isSome:
      return ok(anb(0'i32, next.nIntVal.unsafeGet()))
  of tkDimension:
    if next.dIntVal.isSome:
      let
        intVal = next.dIntVal.unsafeGet()
        unit = next.unit

      case unit.toLowerAscii()
      of "n":
        return parseB(input, intVal)
      of "n-":
        return parseSignlessB(input, intVal, -1)
      else:
        let pres = parseNDashDigits(unit)

        if pres.isOk:
          return ok(anb(next.dIntVal.unsafeGet(), pres.get()))
        else:
          return
            err(input.newBasicUnexpectedTokenError(Token(kind: tkIdent, ident: unit)))
  of tkIdent:
    let value = next.ident

    case value.toLowerAscii()
    of "even":
      return ok(anb(2'i32, 0'i32))
    of "odd":
      return ok(anb(2'i32, 1'i32))
    of "n":
      return parseB(input, 1'i32)
    of "-n":
      return parseB(input, -1'i32)
    of "n-":
      return parseSignlessB(input, 1'i32, -1'i32)
    of "-n-":
      return parseSignlessB(input, -1'i32, -1'i32)
    else:
      let (slice, a) =
        if value.startsWith("-"):
          (value[1 .. value.len - 1], -1'i32)
        else:
          (value, 1'i32) # FIXME: this is not standards compliant, I think

      let pres = parseNDashDigits(slice)
      if pres.isOk:
        return ok(anb(a, pres.get()))
      else:
        return
          err(input.newBasicUnexpectedTokenError(Token(kind: tkIdent, ident: value)))
  of tkDelim:
    if next.delim == '+':
      let rdnext = input.nextIncludingWhitespace()

      if rdnext.isOk:
        let dnext = get rdnext
        if dnext.kind == tkIdent:
          let value = dnext.ident

          case value.toLowerAscii()
          of "n":
            return parseB(input, 1'i32)
          of "n-":
            return parseSignlessB(input, 1'i32, -1'i32)
          else:
            let pres = parseNDashDigits(value)
            if pres.isOk:
              return ok(anb(1'i32, pres.get()))
            else:
              return err(
                input.newBasicUnexpectedTokenError(Token(kind: tkIdent, ident: value))
              )
  else:
    discard

  err(input.newBasicUnexpectedTokenError(next))
