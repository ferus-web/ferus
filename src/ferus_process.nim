import std/[os, options, strutils, parseopt, logging]
import colored_logger
import ferus_ipc/client/[prelude, logger]
import components/[network/process, renderer/process]

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
          quit(1)
      of "kind":
        try:
          process.kind = FerusProcessKind(p.val.parseInt())
        except ValueError:
          quit(1)
      of "ipc-path":
        path = some p.val
      else:
        discard
    else:
      discard

proc main() {.inline.} =
  sandbox()

  var
    p = initOptParser(commandLineParams())
    process = FerusProcess(pid: uint64 getCurrentProcessId())
    client = newIPCClient()
    path: Option[string]

  addHandler newIPCLogger(lvlAll, client)

  bootstrap(p, process, path)
  client.identifyAs(process)
  discard client.connect(path)
  client.handshake()

  case process.kind
  of Network:
    echo "network logic"
    networkProcessLogic(client, process)
  of Renderer:
    renderProcessLogic(client, process)
  else:
    discard

when isMainModule:
  main()
