import std/[strutils, logging]
import colored_logger
import components/[
  build_utils, 
  master/master, network/ipc, renderer/ipc
]
import sanchar/parse/url

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
  
  var list = newDisplayList()
  list.add(
    newTextNode(
      "Hey there - hold on whilst we fetch some network content from a site!", 
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

  master.summonRendererProcess()
  master.loadFont("assets/fonts/IBMPlexSans-Regular.ttf", "Default")
  master.setWindowTitle("Ferus - Loading")
  master.dispatchRender(list)
  
  master.summonNetworkProcess(0)
  let data = master.fetchNetworkResource(0, parse "http://motherfuckingwebsite.com")
  print data
  
  list.reset()
  list.add(
    newTextNode("We're done with fetching data from the site and we also saved the cookies to disk!", vec2(0, 100), "Default")
  )
  master.dispatchRender(list)  
  master.setWindowTitle("Ferus - Done")

  while true:
    master.poll()

when isMainModule:
  main()
