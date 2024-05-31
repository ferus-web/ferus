import stylus/[shared, tokenizer]

type
  Stylesheet* = ref object
    rules*: seq[Rule]

  Declaration* = ref object of ComponentValue
    name*: string
    value*: seq[ComponentValue]
    important*: bool

  SelectorKind* = enum
    skType, skId, skAttr, skClass, skUniversal,
    skPseudoClass, skPseudoElem

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
    of skPseudoClass:
      pclass*: PseudoData
    of skPseudoElem:
      elem*: PseudoElem

  PseudoClass* = enum
    pcFirstChild, pcLastChild, pcOnlyChild, pcHover, pcRoot, pcNthChild,
    pcNthLastChild, pcChecked, pcFocus, pcIs, pcNot, pcWhere, pcLang, pcLink,
    pcVisited

  ParsedItem* = ref object of RootObj
  ComponentValue* = ref object of ParsedItem
  
  Rule* = ref object of ParsedItem
    prelude*: seq[ComponentValue]
    oblock*: SimpleBlock

 # CSSBlock* = ref object
 #   tokens*: seq[Token]
 
  AtRule* = ref object of Rule
    name*: string

  AnB* = object
    a*, b*: int32

  PseudoData* = ref object
    case class*: PseudoClass
    of pcNthChild, pcNthLastChild:
      anb*: AnB
      ofsels*: SelectorList
    of pcIs, pcWhere, pcNot:
      fsels*: SelectorList
    of pcLang:
      s*: string
    else: discard

  CombinatorKind* = enum
    ckNone, ckDescendant, ckChild, ckNextSibling, ckSubsequentSibling

  PseudoElem* = enum
    peNone, peBefore, peAfter

  CompoundSelector* = object
    kind*: CombinatorKind
    selectors*: seq[Selector]

  ComplexSelector* = seq[CompoundSelector]
  SelectorList* = seq[ComplexSelector]

  Function* = ref object of ComponentValue
    name*: string
    value*: seq[ComponentValue]

  QualifiedRule* = ref object of Rule

  SimpleBlock* = ref object of ComponentValue
    token*: Token
    value*: seq[ComponentValue]

proc anb*(a, b: int32): AnB {.inline, noSideEffect, gcsafe.} =
  AnB(a: a, b: b)

iterator items*(sels: CompoundSelector): Selector {.inline.} =
  for it in sels.selectors:
    yield it

proc `[]`*(sels: CompoundSelector; i: int): Selector {.inline.} =
  return sels.selectors[i]

proc `[]`*(sels: CompoundSelector; i: BackwardsIndex): Selector {.inline.} =
  return sels.selectors[i]

proc len*(sels: CompoundSelector): int {.inline.} =
  return sels.selectors.len

proc add*(sels: var CompoundSelector; sel: Selector) {.inline.} =
  sels.selectors.add(sel)
