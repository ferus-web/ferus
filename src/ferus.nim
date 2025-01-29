import std/[os, strutils, logging, tables]
import colored_logger
import components/[
  build_utils, argparser,
  master/master, network/ipc, renderer/ipc, shared/sugar,
  web/controller
]
import components/parsers/html/document
import sanchar/parse/url
import pretty

{.passC: gorge("pkg-config --cflags openssl").strip().}
{.passL: gorge("pkg-config --libs openssl").strip().}

proc setupLogging() {.inline.} =
  addHandler newColoredLogger()
  setLogFilter(lvlInfo)

proc showHelp(code: int = 1) {.noReturn.} =
  echo """
Ferus options
  --help, -h            Print this message
  --version, -v         Show the version of Ferus installed
"""
  quit(code)

proc showVersion {.noReturn.} =
  echo """
Ferus $1

Compiler: $1
Compile Time: $2
Target CPU: $3
""" % [getVersion(), $getCompilerType(), $getCompileDate(), $getArchitecture()]
  quit(0)

proc main() {.inline.} =
  setupLogging()
  let input = parseInput()
  if input.enabled("help", "h"):
    showHelp(0)

  if input.enabled("version", "v"):
    showVersion()

  if input.arguments.len < 1:
    error "Usage: ferus <file / URL>"
    error "Run --help for more information."
    quit(1)

  info "Ferus " & getVersion() & " launching!!"
  info ("Compiled using $1; compiled on $2" % [$getCompilerType(), $getCompileDate()])
  info "Architecture: " & $getArchitecture()
  info "Host OS: " & $getHostOS()

  var resource = input.arguments[0]

  var master = newMasterProcess()
  master.initialize()
  
  if not resource.startsWith("http") and not resource.startsWith("https"):
    resource = "file://" & resource

  master.summonRendererProcess()
  master.loadFont("assets/fonts/IBMPlexSans-Regular.ttf", "Default")
  var tabs: seq[WebMasterController]

  var tab1 = newWebMasterController(parse(resource), master, 0) # Tab 1
  tab1.load()
  tabs.add(tab1.move())

  while true:
    master.poll()
    for i, _ in tabs:
      tabs[i].heartbeat()

when isMainModule:
  main()
