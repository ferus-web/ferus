import std/[tables, logging, options]
import components/layout_v2/[solver, node]
import components/parsers/html/document
import components/web/dom
import pixie, pretty, colored_logger

addHandler(newColoredLogger())

let strm = newStringStream(
  """
<!DOCTYPE html>
<html>
  <head>
    <title>Hello Ferus!</title>
  </head>
  <body>
    <p>Hello Ferus!</p>
    <p>This is the second paragraph.</p>
  </body>
</html>
"""
)

var doc = parseHtml(strm).parseHtmlDocument()
var root = constructLayoutTreeFromDocument(doc)
root.solveLayout(vec2(1280, 720), readFont("assets/fonts/IBMPlexSans-Regular.ttf"))

echo root.children.len
#for child in root.children:
#  print child.processed.position
