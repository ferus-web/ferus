import std/[strutils, logging]
import colored_logger
import components/[
  build_utils,
  master/master
]

proc setupLogging* {.inline.} =
  addHandler newColoredLogger()

proc main {.inline.} =
  setupLogging()

  info "Ferus " & getVersion() & " launching!!"
  info ("Compiled using $1; compiled on $2" % [$getCompilerType(), $getCompileDate()])
  info "Architecture: " & $getArchitecture()
  info "Host OS: " & $getHostOS()

  let master = newMasterProcess()
  initialize master

when isMainModule:
  main()
