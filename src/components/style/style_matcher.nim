import std/[algorithm, options]
import ../parsers/css/[types, selector_parser, keywords]
import ../../components/parsers/html/document
import ./selector_engine

func `<`*(a, b: Selector): bool =
  a.getSpecificity() < b.getSpecificity()

proc sortStylesheetBySpecificity*(sheet: var Stylesheet) =
  ## Sort the stylesheet rules by the selectors' specificity.
  ## This uses the `getSpecificity` function in Ferus' CSS component.
  ## 
  ## Here's what the CSS3 spec says:
  ## 9. Calculating a selector's specificity
  ## A selector's specificity is calculated as follows:
  ## count the number of ID selectors in the selector (= a)
  ## count the number of class selectors, attributes selectors, and pseudo-classes in the selector (= b)
  ## count the number of type selectors and pseudo-elements in the selector (= c)
  ## ignore the universal selector 
  ## Selectors inside the negation pseudo-class are counted like any other, but the negation itself does not count as a pseudo-class.
  ## Concatenating the three numbers a-b-c (in a number system with a large base) gives the specificity.

  sheet = sheet.sortedByIt(it.selector)

proc getMatchingRules*(target: HTMLElement, sheet: Stylesheet): Stylesheet =
  ## Get the matching rules for a particular HTML element from a stylesheet.
  var matching: Stylesheet

  for rule in sheet:
    if rule.selector.matches(target):
      matching &= rule

  ensureMove(matching)

proc getProperty*(
    sheet: Stylesheet, target: HTMLElement, property: Property
): Option[CSSValue] =
  let rules = target.getMatchingRules(sheet)

  for rule in rules:
    if rule.key != $property:
      continue

    return some(rule.value)

export Property
