import std/strformat
import chronicles
import utils
import dom/document

proc main =
  info fmt"[src/ferus.nim] Ferus {getVersion()} starting up!!"

  when defined(windows) or defined(mac):
    fatal "[src/ferus.nim] We're extremely sorry, but we do not support Windows and Mac as of yet due to how complicated their security and sandboxing APIs are. We will NOT ship a broken, unstable and unsafe Ferus until confirmed to be up-to-par. Thank you for 'trying' out Ferus, though. :)"
    quit 1

  var d = newDocument()
  d.parseFromFile("data/pages/test.html")

when isMainModule:
  main()
