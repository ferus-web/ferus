#[
 Basic cookie class

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import std/[times, marshal], chronicles

type
 SameSite* = enum
  ssDefault
  ssNone
  ssStrict
  ssLax

 Source* = enum
  sHttp
  sNonHttp

 Cookie* = ref object of RootObj
  name*: string
  value*: string

  creationTime*: DateTime
  lastAccessTime*: DateTime
  expiryTime*: DateTime
 
  domain*: string
  path*: string

  secure*: bool
  httpOnly*: bool
  hostOnly*: bool
  persistent*: bool

proc serialize*(cookie: Cookie): string {.inline.} =
 $$cookie

proc newCookieFromSerialized*(str: string): Cookie {.inline.} =
 to[Cookie](str)

proc newCookie*(name, value, domain, path: string,
                creationTime, lastAccessTime, expiryTime: DateTime,
                secure, httpOnly, hostOnly, persistent: bool) {.inline.} =
 Cookie(name: name, value: value, domain: domain, path: path, creationTime: creationTime, 
        lastAccessTime: lastAccessTime, expiryTime: expiryTime, secure: secure, 
        httpOnly: httpOnly, hostOnly: hostOnly, persistent: persistent)