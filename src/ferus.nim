import std/strformat
import chronicles
import utils
import app

proc main =
  info fmt"[src/ferus.nim] Ferus {getVersion()} starting up!!"

  when defined(windows) or defined(mac):
    fatal "[src/ferus.nim] We're extremely sorry, but we do not support Windows and Mac as of yet due to how complicated their security and sandboxing APIs are. We will NOT ship a broken, unstable and unsafe Ferus until confirmed to be up-to-par. Thank you for 'trying' out Ferus, though. :)"
    quit 1

  when defined(danger):
    fatal "[src/ferus.nim] Ferus does not support compilation with -d:danger as many checks are not properly implemented yet."
    quit 1

  var app = newFerusApplication()
  app.initRenderer()

when isMainModule:
  main()
