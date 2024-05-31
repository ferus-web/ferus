import std/[strutils, logging]
import colored_logger
import components/[
  build_utils, 
  master/master, network/ipc, renderer/ipc
]
import sanchar/parse/url
import pretty

proc setupLogging*() {.inline.} =
  addHandler newColoredLogger()

proc main() {.inline.} =
  setupLogging()

  info "Ferus " & getVersion() & " launching!!"
  info ("Compiled using $1; compiled on $2" % [$getCompilerType(), $getCompileDate()])
  info "Architecture: " & $getArchitecture()
  info "Host OS: " & $getHostOS()

  let master = newMasterProcess()
  initialize master

  #let data = master.fetchNetworkResource(0, parse "http://")
  #print data
  
  let src = """
body {
  background-color: rgb(25, 25, 25);
}
  """

  let rules = master.parseCssRules(src)

  var list = newDisplayList()
  list.add(
    newTextNode(
      "Hey there - this is a text node created by the master process and sent to the renderer process via Ferus' IPC layer!", 
      vec2(0, 100),
      "Default"
    )
  )

  list.add(
    newGIFNode(
      "assets/gifs/justa.gif",
      vec2(0, 150)
    )
  )

  list.add(
    newTextNode(
      "Recompile with -d:ferusgfxDrawDamagedRegions to see cool stuff! (epilepsy warning)",
      vec2(0, 800),
      "Default"
    )
  )

  list.add(
    newImageNode(
      "assets/images/ferus_logo.png",
      vec2(20, 850)
    )
  )

  list.add(
    newTextNode(
      "That's the Ferus logo. Expect more to come soon!",
      vec2(0, 950),
      "Default"
    )
  )

  master.summonRendererProcess()
  master.loadFont("assets/fonts/IBMPlexSans-Regular.ttf", "Default")
  master.setWindowTitle("Ferus - This was set from the master process!")
  master.dispatchRender(list)

  while true:
    master.poll()

when isMainModule:
  main()
