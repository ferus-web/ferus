#[
  Process Type definitions for Ferus

  This code is licensed under the MIT license
]#

import strutils

type ProcessType* = enum
  ptRenderer,
  ptHtmlParser,
  ptNetwork,
  ptCssParser,
  ptBaliRuntime

proc processTypeToString*(procType: ProcessType): string =
  if procType == ptRenderer:
    return "renderer"
  elif procType == ptHtmlParser:
    return "html"
  elif procType == ptNetwork:
    return "net"
  elif procType == ptCssParser:
    return "css"
  elif procType == ptBaliRuntime:
    return "bali"
  else:
    raise newException(ValueError, "Invalid procType")

proc stringToProcessType*(str: string): ProcessType =
  var x = str.toLower()
  if x == "renderer":
    return ptRenderer
  elif x == "html":
    return ptHtmlParser
  elif x == "net":
    return ptNetwork
  elif x == "css":
    return ptCssParser
  elif x == "bali":
    return ptBaliRuntime
  else:
    raise newException(ValueError, "Invalid str")
