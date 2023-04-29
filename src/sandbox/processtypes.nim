#[
  Process Type definitions for Ferus

  This code is licensed under the MIT license
]#

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
