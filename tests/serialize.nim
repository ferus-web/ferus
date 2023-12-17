import std/marshal
import ../src/dom/dom, 
       ../src/dom/document, 
       ../src/parsers/html/element,
       ../src/parsers/html/dump

let data = """
<html>
  <head>
    <title>Hi</title>
  </head>
  <body>
    <p1>Hi</title>
  </body>
</html>
"""

var x = newDOM()
x.document.parseHTML(data)

let y = $$x
let z = to[DOM](y)

echo "Z: " & z.document.root.dump(0) & "\n\n"
echo "X: " & x.document.root.dump(0) 
