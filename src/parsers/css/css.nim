import std/tables
import ../../butterfly

type
  CSSParserState* = enum                  # Example
    psReadName,                        # myH1
    psParseAttrName,                   #    color:
    psParseAttrValue,                  #    rgba(234, 88, 126, .5);
    psEndAttrib,
    psBadAttrib,
    psEndTag

  CSSParser* = ref object of RootObj
    state*: CSSParserState

proc isWhitespace*(c: char): bool =
  c == ' ' or c == '\n' or c == '\t'

proc parse*(parser: CSSParser, input: string): TableRef[string, TableRef[string, string]] =
  var 
    elementName = ""
    currentAttribName = ""
    currentAttribValue = ""
    # TODO: Finish src/butterfly.nim so that it can be used here and in the HTML parser
    attributes = newTable[string, TableRef[string, string]]()

  for c in input:
    if isWhitespace(c):
      continue

    if parser.state == CSSParserState.psEndAttrib:
      echo "endAttrib"
      echo "eName: " & elementName
      echo "can: " & currentAttribName
      echo "cav: " & currentAttribValue
      echo "============\n"
      attributes[elementName][currentAttribName] = currentAttribValue

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
      attributes[elementName] = newTable[string, string]()
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

  attributes

proc newCSSParser*: CSSParser =
  CSSParser(state: CSSParserState.psReadName)
