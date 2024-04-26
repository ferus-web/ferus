import std/[strutils, logging]
import colored_logger
import components/[build_utils, master/master, network/ipc, renderer/ipc]
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

  #var list = newIPCDisplayList()
  #list.add(
  #  newTextNode(
  #    "Hey there", 
  #    vec2(0, 300),
  #    "Default"
  #  )
  #)

  master.summonRendererProcess()
  master.loadFont("assets/IBMPlexSans-Regular.ttf", "Default")
  master.setWindowTitle("Ferus - This was set from the master process!")
  # master.dispatchRender(list)

  while true:
    master.poll()

when isMainModule:
  main()
