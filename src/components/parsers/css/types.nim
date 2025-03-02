import std/[options]
import stylus/[shared, tokenizer]
import ./units

type
  SelectorKind* = enum
    skType
    skId
    skAttr
    skClass
    skUniversal # skPseudoClass, skPseudoElem

  Selector* = ref object
    case kind*: SelectorKind
    of skType:
      tag*: string
    of skId:
      id*: string
    of skClass:
      class*: string
    of skAttr:
      attr*: string
    of skUniversal: discard

  PseudoClass* = enum
    pcFirstChild
    pcLastChild
    pcOnlyChild
    pcHover
    pcRoot
    pcNthChild
    pcNthLastChild
    pcChecked
    pcFocus
    pcIs
    pcNot
    pcWhere
    pcLang
    pcLink
    pcVisited

  # CSSBlock* = ref object
  #   tokens*: seq[Token]
  AtRule* = object of Rule
    name*: string

  AnB* = object
    a*, b*: int32

  CombinatorKind* = enum
    ckNone
    ckDescendant
    ckChild
    ckNextSibling
    ckSubsequentSibling

  PseudoElem* = enum
    peNone
    peBefore
    peAfter

  CSSValueKind* = enum
    cssFunction
    cssInteger
    cssFloat
    cssString
    cssDimension
    cssHex

  CSSUnit* {.pure.} = enum
    Px
    Cm
    Mm
    In

  CSSDimension* = object
    value*: float32
    unit*: CSSUnit

  CSSFunction* = object
    name*: string
    arguments*: seq[CSSValue]

  CSSValue* = object
    case kind*: CSSValueKind
    of cssFunction:
      fn*: CSSFunction
    of cssInteger:
      num*: int32
    of cssFloat:
      flt*: float32
    of cssString:
      str*: string
    of cssHex:
      hex*: string
    of cssDimension:
      dim*: CSSDimension

  Stylesheet* = seq[Rule]

  Rule* = object of RootObj
    selector*: Selector
    key*: string
    value*: CSSValue

func function*(name: string, arguments: seq[CSSValue]): CSSValue {.inline.} =
  CSSValue(kind: cssFunction, fn: CSSFunction(name: name, arguments: arguments))

func number*(num: int32): CSSValue {.inline.} =
  CSSValue(kind: cssInteger, num: num)

func decimal*(dec: float32): CSSValue {.inline.} =
  CSSValue(kind: cssFloat, flt: dec)

func dimension*(value: float32, unit: CSSUnit): CSSValue {.inline.} =
  CSSValue(kind: cssDimension, dim: CSSDimension(value: value, unit: unit))

func toPixels*(value: CSSValue): float =
  assert(value.kind == cssDimension, "BUG: toPixels() called on non-dimensional CSS value!")

  case value.dim.unit
  of CSSUnit.Px:
    return value.dim.value
  of CSSUnit.Mm:
    # FIXME: very silly calculations
    # we're assuming the display will only have 96 pixels per inch...
    return (value.dim.value * 96) / 25.4
  of CSSUnit.Cm:
    # FIXME: very silly calculations, part 2
    return (value.dim.value * 96) / 2.54
  of CSSUnit.In:
    # FIXME: very silly calculations: electric boogaloo
    return value.dim.value * 96

func parseUnit*(str: string): Option[CSSUnit] =
  if not Units.contains(str):
    return

  case str
  of "px":
    return some(CSSUnit.Px)
  of "mm":
    return some(CSSUnit.Mm)
  of "cm":
    return some(CSSUnit.Cm)
  of "in":
    return some(CSSUnit.In)
  else:
    discard

func str*(str: string): CSSValue {.inline.} =
  CSSValue(kind: cssString, str: str)

func tagSelector*(tag: string): Selector {.inline.} =
  Selector(kind: skType, tag: tag)

func anb*(a, b: int32): AnB {.inline.} =
  AnB(a: a, b: b)
