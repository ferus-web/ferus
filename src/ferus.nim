import std/[os, strutils, logging, tables]
import colored_logger
import components/[
  build_utils, 
  master/master, network/ipc, renderer/ipc, shared/sugar
]
import sanchar/parse/url
import pretty

proc setupLogging*() {.inline.} =
  addHandler newColoredLogger()

proc main() {.inline.} =
  setupLogging()

  if paramCount() < 1:
    quit "Usage: ferus [url/file]"

  info "Ferus " & getVersion() & " launching!!"
  info ("Compiled using $1; compiled on $2" % [$getCompilerType(), $getCompileDate()])
  info "Architecture: " & $getArchitecture()
  info "Host OS: " & $getHostOS()

  let master = newMasterProcess()
  initialize master
  
  let resource = paramStr(1)
  var content: string

  if resource.startsWith("https://") or resource.startsWith("http://"):
    let data = master.fetchNetworkResource(0, paramStr(1))

    if not *data:
      error "Failed to fetch HTTP resource"
      quit(1)

    let resp = &(&data).response # i love unwrapping
    print(resp)

    content = resp.content
  else:
    if not fileExists(resource):
      error "Failed to find file"
      quit(1)

    content = readFile(resource)
  
  master.summonHTMLParser(0)
  let parsedHtml = master.parseHTML(0, content)

  if not *parsedHtml:
    error "Failed to parse HTML"
    quit(1)

  let document = &(&parsedHtml).document # i love unwrapping: electric boogaloo
  print document

  master.summonRendererProcess()
  master.loadFont("assets/fonts/IBMPlexSans-Regular.ttf", "Default")
  master.renderDocument(document)

  while true:
    master.poll()

when isMainModule:
  main()
