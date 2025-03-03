import std/[tables]
import components/parsers/css/parser
import pretty

var src = readFile "assets/user-agent.css"

let css = newCSSParser(src)
let rules = css.consumeRules()
print rules
