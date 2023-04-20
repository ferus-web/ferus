import chronicles
import element

type 
  ParserState* = enum
    psInit,
    psStartTag,
    psReadingTag,
    psReadingAttributes,
    psEndTag,
    psBeginClosingTag

  Parser* = ref object of HTMLElement
    state*: ParserState

proc isWhitespace*(c: char): bool =
  c == ' '

proc parse*(parser: Parser, input: string, root: HTMLElement): HTMLElement =
  var lastParent: HTMLElement = root
  var tagName: string = ""

  for c in input:
    if c == '<':
      parser.state = ParserState.psStartTag
    elif parser.state == ParserState.psStartTag:
      if c == '/':
        parser.state = ParserState.psBeginClosingTag
      elif not isWhitespace(c):
        parser.state = ParserState.psReadingTag
        tagName = tagName & c
    elif parser.state == ParserState.psReadingTag:
      if isWhitespace(c):
        parser.state = ParserState.psReadingAttributes
      elif c == '>':
        # We are now ending the parsing, this element is either fully constructed or malformed.
        parser.state = ParserState.psEndTag
        
        # Construct the new element itself.
        var parent = newHTMLElement(tagName, "", root)
        parent.parentElement = lastParent
        
        # Finally, add this to the last parent's children, and then override the last parent
        # with this new child itself.
        lastParent.children.add(parent)
        lastParent = parent
      else:
        tagName = tagName & c
    elif parser.state == ParserState.psReadingAttributes:
      if c == '>':
        parser.state = ParserState.psEndTag

        var parent = newHTMLElement(tagName, "", root)
        parent.parentElement = lastParent

        lastParent.children.add(parent)
        lastParent = parent
    elif parser.state == ParserState.psEndTag:
      lastParent.textContent = lastParent.textContent & c
    elif parser.state == ParserState.psBeginClosingTag:
      if c == '>':
        lastParent = lastParent.parentElement

  lastParent

proc newParser*: Parser =
  Parser(state: ParserState.psInit)
