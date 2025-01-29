## Master controller
import std/[os, logging, strutils, tables]
import sanchar/parse/url
import ../../components/parsers/html/document
import ../../components/[
  master/master, network/ipc, renderer/ipc, shared/sugar
]
import pkg/[pretty]

type
  WebMasterController* = object
    document*: HTMLDocument
    master*: MasterProcess
    tab*: uint
    url*: URL

proc executeJavaScript*(controller: var WebMasterController) =
  # FIXME: this is not the compliant way to execute JS - make it compliant!
  var scriptNodes: seq[HTMLElement] 

  for node in controller.document.elems:
    scriptNodes &= node.findAll(TAG_SCRIPT, descend = true)

  for node in scriptNodes:
    let text = node.text()

    if !text: continue

    controller.master.executeJS(controller.tab, code = &text)
    break

proc load*(controller: var WebMasterController) =
  info "controller: master controller for tab " & $controller.tab & " is loading."
  controller.master.summonJSRuntime(controller.tab)
  controller.master.summonNetworkProcess(controller.tab)
  controller.master.summonHTMLParser(controller.tab)
  var data: string

  if controller.url.scheme == "file":
    var location = $controller.url
    location.removePrefix("file://")

    if not fileExists(location):
      error "controller: no such file: " & location
      quit(1)

    data = readFile(location)
  else:
    controller.master.urls[controller.tab] = controller.url
    let content = controller.master.fetchNetworkResource(
      controller.tab, $controller.url
    )

    if !content:
      error "controller: failed to fetch resource for tab " & $controller.tab
      quit(1)

    data = (&content).content()
    
  let doc = controller.master.parseHTML(controller.tab, data)

  if !doc:
    controller.document = default(HTMLDocument)
  else:
    let unwrapped = &doc
    if *unwrapped.document:
      controller.document = &((&doc).document)
    else:
      controller.document = default(HTMLDocument)
  
  controller.document.url = controller.url
  controller.master.updateDocumentState(controller.tab, controller.document)
  controller.executeJavaScript()
  controller.master.renderDocument(controller.document)

proc heartbeat*(controller: var WebMasterController) =
  # This is run in Ferus' main loop
  if controller.master.urls.len < 1:
    # No website is open right now, weird.
    return

  if controller.master.urls[controller.tab] != controller.url:
    # the renderer called `feRendererGotoURL`, probably
    controller.url = controller.master.urls[controller.tab]
    controller.load()

func newWebMasterController*(
  url: URL,
  master: MasterProcess,
  tab: uint
): WebMasterController =
  WebMasterController(
    master: master,
    tab: tab,
    url: url
  )
