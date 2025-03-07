import std/[tables]
import components/parsers/css/parser
import pretty

var src = """
      h1 {
        font-size: 64px;
      }

"""

let css = newCSSParser(src)
let rules = css.consumeRules()
print rules
