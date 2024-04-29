import stylus/tokenizer

type
  Stylesheet* = ref object
    rules*: seq[Rule]

  Rule* = ref object
    selectors*: seq[Selector]
    declarations*: seq[Declaration]

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
  ComponentValue* = ref object of CSSParsedItem
  
  Rule* = ref object of ParsedItem
    prelude*: seq[ComponentValue]
    oblock*: CSSBlock

  CSSBlock* = ref object
    tokens*: seq[Token]

  AnB* = object
    a*, b*: int

  PseudoData* = ref object
    case class*: PseudoClass
    of pcNthChild, pcNthLastChild:
      anb*: AnB

