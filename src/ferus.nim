import std/[strformat]
import parsers/dom
import parsers/html/handy
import chronicles
import utils

var data = """
<h1>Hello World!</h1>
<p>Hi</p>
"""

proc main =
  info fmt"[src/ferus.nim] Ferus {getVersion()} starting up!!"
  var dom = newDOM()
  parseFromFile(dom, "data/pages/test.html", true)

  echo dumpDOM(dom)

when isMainModule:
  main()
