#[
  State machine based HTML parser for Ferus.
  
  This code is licensed under the MIT license.
]#

import chronicles
import element

type 
  ParserState* = enum
    psInit,
    psStartTag,
    psComment,
    psReadingTag,
    psReadingAttributes,
    psEndTag,
    psBeginClosingTag

  Parser* = ref object of HTMLElement
    state*: ParserState

proc isWhitespace*(c: char): bool =
  c == ' '

proc parse*(parser: Parser, input: string, root: HTMLElement): HTMLElement =
  var
    lastParent: HTMLElement = root
    tagName: string = ""

    index: int = -1

  for c in input:
    # Consume whitespace.
    if isWhitespace(c):
      continue
  
    inc index

    # Comment handler
    if parser.state == ParserState.psComment:
      if c == '-':
        if index + 1 < input.len and index + 2 < input.len:
          if input[index + 1] == '-' and input[index + 2] == '>':
            # Comment end! We now pretend that a tag has just ended.
            parser.state = ParserState.psEndTag
            continue

    if c == '<':
      # Code to handle comments. They're just discarded by the parser.
      #   !                                 -                     -
      if index + 1 < input.len and index + 2 < input.len and index + 3 < input.len:
        if input[index + 1] == '!' and input[index + 2] == '-' and input[index + 3] == '-':
          # Comment detected!
          parser.state = ParserState.psComment
          continue
        
      parser.state = ParserState.psStartTag
    elif parser.state == ParserState.psStartTag:
      if c == '/':
        parser.state = ParserState.psBeginClosingTag
      else:
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
