import std/[tables]
import components/parsers/css/parser
import pretty

var src = """
      h1 {
        width: 50%;
      }
"""

let css = newCSSParser(src)
let rules = css.consumeRules()
print rules
