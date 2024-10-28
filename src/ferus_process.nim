import std/[os, options, strutils, parseopt, logging]
import colored_logger
import ferus_ipc/client/[prelude, logger]
import components/[network/process, renderer/process, parsers/html/process, js/process]

when defined(linux):
  import components/sandbox/linux

proc bootstrap(
    p: var OptParser, process: var FerusProcess, path: var Option[string]
) {.inline.} =
  while true:
    next p
    case p.kind
    of cmdEnd:
      break
    of cmdLongOption:
      case p.key
      of "worker":
        try:
          process.worker = parseBool(p.val)
        except ValueError:
          quit(249)
      of "kind":
        try:
          process = FerusProcess(kind: FerusProcessKind(p.val.parseInt()))
        except ValueError:
          quit(250)
      of "ipc-path":
        path = some p.val
      of "pKind":
        assert process.kind == Parser, "`parser-kind` was specified, but `kind` is NOT `Parser`! Something has went horribly, horribly wrong!"
        try:
          process = FerusProcess(kind: Parser, pKind: ParserKind(p.val.parseInt()))
        except ValueError:
          quit(251)
      else:
        discard
    else:
      discard

proc main() {.inline.} =
  var
    p = initOptParser(commandLineParams())
    process = FerusProcess(pid: uint64 getCurrentProcessId())
    client = newIPCClient()
    path: Option[string]
  
  addHandler newColoredLogger()
  bootstrap(p, process, path)

  process.pid = uint64 getCurrentProcessId()
  client.identifyAs(process)

  info "Bootstrap: Kind: " & $process.kind

  if process.kind == Parser:
    info "Bootstrap: Parser Kind: " & $process.pKind
  discard client.connect(path)
  client.handshake()
  
  addHandler newIPCLogger(lvlAll, client)
  setLogFilter(lvlInfo)
  
  if process.kind != Renderer:
    sandbox(process.kind)

  case process.kind
  of Network:
    networkProcessLogic(client, process)
  of Renderer:
    renderProcessLogic(client, process)
  of Parser:
    htmlParserProcessLogic(client, process)
  of JSRuntime:
    jsProcessLogic(client, process)
  else:
    discard

when isMainModule:
  main()
