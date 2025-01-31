import std/logging
import components/layout/[processor, box]
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
  </body>
</html>
"""
)

let document = parseHtml(strm)
var layout =
  newLayout(readFont("assets/fonts/IBMPlexSans-Regular.ttf"), rect(0, 0, 1280, 720))
layout.constructFromDocument(document)
print layout.boxes

for box in layout.boxes:
  let txt = TextBox(box)
  print txt
