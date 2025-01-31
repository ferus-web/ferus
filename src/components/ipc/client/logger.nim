## A soft shell around `std/logging` to easily attach a log handler that redirects all logs to the IPC server.
## Copyright (C) 2024 Trayambak Rai and Ferus Authors
import std/[logging]
import ./[client]

type IPCLogger* = ref object of ConsoleLogger
  ipc*: IPCClient

proc newIPCLogger*(levelThreshold = lvlAll, ipc: IPCClient): IPCLogger {.inline.} =
  IPCLogger(ipc: ipc, levelThreshold: levelThreshold)

method log*(logger: IPCLogger, level: Level, args: varargs[string, `$`]) {.gcsafe.} =
  let msg = substituteLog("", level, args)

  case level
  of lvlAll, lvlInfo:
    logger.ipc.info(msg)
  of lvlWarn:
    logger.ipc.warn(msg)
  of lvlError, lvlFatal:
    logger.ipc.error(msg)
  else:
    logger.ipc.debug(msg)
