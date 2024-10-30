import std/[os, strutils, logging, tables]
import colored_logger
import components/[
  build_utils, 
  master/master, network/ipc, renderer/ipc, shared/sugar
]
import components/parsers/html/document
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

  var master = newMasterProcess()
  initialize master
  master.summonJSRuntime(0)
  master.summonNetworkProcess(0)
  master.summonRendererProcess()
  master.loadFont("assets/fonts/IBMPlexSans-Regular.ttf", "Default")
  
  let resource = paramStr(1)
  var content: string

  if resource.startsWith("https://") or resource.startsWith("http://"):
    let data = master.fetchNetworkResource(0, resource)
    master.urls.add(resource)

    if not *data:
      error "Failed to fetch HTTP resource"
      quit(1)

    let resp = &data

    content = resp.content()
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
  var scriptNodes: seq[HTMLElement] 

  for node in document.elems:
    scriptNodes &= node.findAll(TAG_SCRIPT, descend = true)

  for node in scriptNodes:
    let text = node.text()

    if !text: continue

    master.executeJS(0, code = &text)
    break

  master.renderDocument(document)

  while true:
    master.poll()

when isMainModule:
  main()
