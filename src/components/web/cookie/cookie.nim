## Cookies implementation
##


import std/[strutils, times]

type
  SameSite* = enum
    ssDefault
    ssNone
    ssStrict
    ssLax

  Source* = enum
    srcNonHttp
    srcHttp

  Cookie* = object
    name*, value*: string
    sameSite*: SameSite

    creation*, lastAccess*, expiry*: DateTime
    domain*, path*: string

    secure*, httpOnly*, hostOnly*, persistent*: bool = false

proc `$`*(ss: SameSite): string {.inline.} =
  case ss
  of ssDefault:
    return "Default"
  of ssNone:
    return "None"
  of ssStrict:
    return "Strict"
  of ssLax:
    return "Lax"

proc sameSite*(str: string): SameSite {.inline.} =
  case str.toLowerAscii()
  of "none":
    ssNone
  of "strict":
    ssStrict
  of "lax":
    ssLax
  else: ssDefault