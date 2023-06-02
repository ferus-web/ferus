#[
  State-machine based CSS parser for Ferus

  This code is licensed under the MIT license
]#

import std/tables
import std/times

import chronicles

import rules/rules
import ../../butterfly

type
  CSSParserState* = enum                  # Example
    psReadName,                        # myH1
    psParseAttrName,                   #    color:
    psParseAttrValue,                  #    rgba(234, 88, 126, .5);
    psEndAttrib,
    psBadAttrib,
    psEndTag
  
  RuleSet* = TableRef[string, TableRef[string, Butterfly]]
  CSSParser* = ref object of RootObj
    state*: CSSParserState

proc isWhitespace*(c: char): bool =
  c == ' ' or c == '\n' or c == '\t'
                                               # ROOT   OBJ     ATTRS   ATTRNAME BUTTERFLY
proc parse*(parser: CSSParser, input: string): RuleSet =
  var
    startTime = cpuTime()
    elementName = ""
    currentAttribName = ""
    currentAttribValue = ""
    attributes = newTable[string, TableRef[string, Butterfly]]()

  for c in input:
    if isWhitespace(c):
      continue

    if parser.state == CSSParserState.psEndAttrib:
      # compute butterfly payload
      var data: string
      try:
        data = getCssTypes(currentAttribName) & "[" & currentAttribValue & "]"
      except KeyError:
        warn "[src/parsers/css.nim] No type in dictionary for this attribute! Defaulting to the good ol' string. (KeyError raised when trying to compare)", erroneousType=currentAttribName
        data = "s[" & currentAttribValue & "]"

      attributes[elementName][currentAttribName] = newButterfly(data)
      
      currentAttribName.reset()
      currentAttribValue.reset()

      if c != '}':
        parser.state = CSSParserState.psParseAttrName
      else:
        elementName.reset()
        parser.state = CSSParserState.psEndTag
        continue

    if parser.state == CSSParserState.psBadAttrib:
      if c != '}':
        parser.state = CSSParserState.psParseAttrName
      else:
        elementName.reset()
        parser.state = CSSParserState.psEndTag
        continue

    if parser.state == CSSParserState.psEndTag:
      parser.state = CSSParserState.psReadName

    if c == '{' and parser.state != CSSParserState.psParseAttrName:
      attributes[elementName] = newTable[string, Butterfly]()
      parser.state = CSSParserState.psParseAttrName
      continue
    elif c != '{' and parser.state == CSSParserState.psReadName:
      elementName = elementName & c
    
    if parser.state == CSSParserState.psParseAttrName:
      if c != ':':
        currentAttribName = currentAttribName & c
      else:
        parser.state = CSSParserState.psParseAttrValue
        continue

    if parser.state == CSSParserState.psParseAttrValue:
      if c == '}':
        echo "[src/parsers/css.nim] Malformed CSS detected; expected attribute value but got '}' instead."
 
      if c != ';':
        currentAttribValue = currentAttribValue & c
      else:
        if currentAttribValue.len < 1:
          echo "[src/parsers/css.nim] No value provided for attribute, got ';' instead. This attribute will not be registered."
          parser.state = CSSParserState.psBadAttrib
        else:
          parser.state = CSSParserState.psEndAttrib
        continue

  info "[src/parsers/css.nim] Parsed CSS successfully!", timeMs=cpuTime() - startTime
  attributes

proc newCSSParser*: CSSParser =
  CSSParser(state: CSSParserState.psReadName)
