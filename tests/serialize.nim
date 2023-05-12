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

echo x.document.root.dump(0)
