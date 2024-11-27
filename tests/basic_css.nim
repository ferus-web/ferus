import std/[tables]
import components/parsers/css/parser
import pretty

const src = """
body {
  background-color: rgb(255, 255, 255);
}
"""

let css = newCSSParser(src)
let rules = css.consumeRules()
print rules
