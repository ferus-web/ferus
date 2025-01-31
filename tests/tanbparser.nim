import std/options
import stylus/parser, results, pretty
import components/parsers/css/anb

const src =
  """
p:nth-child(2n) {
  background-color: rgb(255, 255, 255);
}
"""

let
  input = newParserInput src
  parserObj = newParser input

let ident = parserObj.expectIdent()
print get(ident)
print parserObj.expectColon()
let fn = parserObj.expectFunctionMatching "nth-child"
print parserObj.expectParenBlock()
let res = parserObj.parseNth()
print get res
