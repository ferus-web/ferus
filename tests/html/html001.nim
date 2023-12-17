#[
  Testing of the chame-based HTML parser

  requires: pretty
]#

import std/streams, pretty, ../../src/html/dombuilder

var codeStream = newStringStream("""
<html>
  <head>
    <title>RIP ferushtml</title>
  </head>
  <body>
    <p>It seems ferus got too ambitious. It's better to use chame as for now, it will reduce a lot of our work and perhaps, sometime later, we can also start contributing to it.</p>
  </body>
</html>
""")

let document = parseHtml(codeStream)

print document
