import stylus/tokenizer

type
  Stylesheet* = ref object
    rules*: seq[Rule]

  Rule* = ref object
    selectors*: seq[Selector]
    #declarations*: seq[Declaration]

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
    of skPseudoElem: discard
    #  elem*: PseudoElem

  PseudoClass* = enum
    pcFirstChild, pcLastChild, pcOnlyChild, pcHover, pcRoot, pcNthChild,
    pcNthLastChild, pcChecked, pcFocus, pcIs, pcNot, pcWhere, pcLang, pcLink,
    pcVisited

  ParsedItem* = ref object of RootObj
  ComponentValue* = ref object of ParsedItem
  
 # Rule* = ref object of ParsedItem
 #   prelude*: seq[ComponentValue]
 #   oblock*: CSSBlock

 # CSSBlock* = ref object
 #   tokens*: seq[Token]

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

  CompoundSelector* = object
    kind*: CombinatorKind
    selectors*: seq[Selector]

  ComplexSelector* = seq[CompoundSelector]
  SelectorList* = seq[ComplexSelector]

proc anb*(a, b: int32): AnB {.inline, noSideEffect, gcsafe.} =
  AnB(a: a, b: b)
