#[
  State machine based HTML parser for Ferus.
  WARNING: DO NOT USE THIS ANYWHERE! THIS SERVES AS JUST AN ABSTRACTION
  TO KEEP THE HTML PARSER CODE CLEAN FROM THE SANDBOXED VERSION!
  USE src/parsers/sandboxed.nim WHEN DEALING WITH UNSAFE CODE!

  This code is licensed under the MIT license.
]#

import chronicles
import element

type 
  HTMLParserState* = enum
    psInit,
    psStartTag,
    psComment,
    psReadingTag,
    psReadingAttributes,
    psEndTag,
    psBeginClosingTag

  HTMLParser* = ref object of HTMLElement
    state*: HTMLParserState

proc isWhitespace*(c: char): bool =
  c == ' '

proc parse*(parser: HTMLParser, input: string, root: HTMLElement): HTMLElement =
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
    if parser.state == HTMLParserState.psComment:
      if c == '-':
        if index + 1 < input.len and index + 2 < input.len:
          if input[index + 1] == '-' and input[index + 2] == '>':
            # Comment end! We now pretend that a tag has just ended.
            parser.state = HTMLParserState.psEndTag
            continue

    if c == '<':
      # Code to handle comments. They're just discarded by the parser.
      #   !                                 -                     -
      if index + 1 < input.len and index + 2 < input.len and index + 3 < input.len:
        if input[index + 1] == '!' and input[index + 2] == '-' and input[index + 3] == '-':
          # Comment detected!
          parser.state = HTMLParserState.psComment
          continue
        
      parser.state = HTMLParserState.psStartTag
    elif parser.state == HTMLParserState.psStartTag:
      if c == '/':
        parser.state = HTMLParserState.psBeginClosingTag
      else:
        parser.state = HTMLParserState.psReadingTag
        tagName = tagName & c
    elif parser.state == HTMLParserState.psReadingTag:
      if isWhitespace(c):
        parser.state = HTMLParserState.psReadingAttributes
      elif c == '>':
        # We are now ending the parsing, this element is either fully constructed or malformed.
        parser.state = HTMLParserState.psEndTag
        
        # Construct the new element itself.
        var parent = newHTMLElement(tagName, "", root)
        parent.parentElement = lastParent
        
        # Finally, add this to the last parent's children, and then override the last parent
        # with this new child itself.
        lastParent.children.add(parent)
        lastParent = parent
      else:
        tagName = tagName & c
    elif parser.state == HTMLParserState.psReadingAttributes:
      if c == '>':
        parser.state = HTMLParserState.psEndTag

        var parent = newHTMLElement(tagName, "", root)
        parent.parentElement = lastParent

        lastParent.children.add(parent)
        lastParent = parent
    elif parser.state == HTMLParserState.psEndTag:
      lastParent.textContent = lastParent.textContent & c
    elif parser.state == HTMLParserState.psBeginClosingTag:
      if c == '>':
        lastParent = lastParent.parentElement

  lastParent

proc newHTMLParser*: HTMLParser =
  HTMLParser(state: HTMLParserState.psInit)
