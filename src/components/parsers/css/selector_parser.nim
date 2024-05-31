import stylus/parser
import ./types

proc getSpecificity*(selectors: CompoundSelector): int {.inline.}
proc getSpecificity*(selectors: ComplexSelector): int {.inline.}

proc getSpecificity*(
  selector: Selector
): int =
  case selector.kind
  of skId:
    result += 1000000
  of skClass, skAttr:
    result += 1000
  of skPseudoClass:
    case selector.pclass.class
    of pcIs, pcNot:
      if selector.pclass.ofsels.len != 0:
        var best: int

        for child in selector.pclass.fsels:
          let s = getSpecificity child
          if s > best:
            best = s

        result += best
      result += 1000
    of pcNthChild, pcNthLastChild:
      if selector.pclass.ofsels.len != 0:
        var best: int

        for child in selector.pclass.ofsels:
          let s = getSpecificity child
          if s > best:
            best = s

        result += best
    of pcWhere: discard
    else: result += 1000
  of skType, skPseudoElem:
    result += 1
  of skUniversal: discard

proc getSpecificity*(
  selectors: CompoundSelector
): int {.inline.} =
  var accumulator: int

  for sel in selectors:
    accumulator += getSpecificity(sel)

  accumulator

proc getSpecificity*(
  selectors: ComplexSelector
): int {.inline.} =
  var accumulator: int

  for sel in selectors:
    accumulator += getSpecificity(sel)

  accumulator

proc pseudo*(complex: ComplexSelector): PseudoElem {.inline.} =
  if complex[^1][^1].kind == skPseudoElem:
    complex[^1][^1].elem
  else:
    peNone
