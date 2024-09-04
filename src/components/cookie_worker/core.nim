import std/[logging, locks, strutils]
import ../shared/sugar
import ../web/cookie/[parsed_cookie, cookie]

import ./[directory, ipc]

import jsony, flatty

type
  CookieWorker* = object
    lock*: Lock
    store* {.guard: lock.}: seq[ParsedCookie]

proc `=destroy`*(worker: var CookieWorker) =
  info "CookieWorker destructor has been called, dumping cookies."

  withLock worker.lock:
    let serialized = toJson(worker.store)
    info "Serialized cookie store: " & serialized

    let target = getCookiesPath()

    info "Storing cookies to: " & target
    
    try:
      writeFile(
        target,
        serialized
      )
    except OSError as exc:
      error "Failed to store cookies to: " & target & " (OSError: " & exc.msg & ')'
      error "Storing cookies to fallback path: ./cookies.bin"
      writeFile("cookies.bin", serialized) # I don't even care if this one fails. You're the one being the idiot here. I'm not responsible for any garbage beyond this.

    `=destroy`(worker.store)
  
  info "Destroying cookie store lock."
  deinitLock(worker.lock)

proc cacheCookie*(worker: var CookieWorker,
                        cookie: ParsedCookie) {.inline.} =
  info "Appending cookie to store [name=$1, value=$2, sameSiteAttribute=$3, domain=$4, path=$5, secure=$6, httpOnly=$7]" % [
    cookie.name, cookie.value, $cookie.sameSiteAttribute, &cookie.domain, &cookie.path, $cookie.secureAttributePresent, $cookie.httpOnlyAttributePresent
  ]
  withLock worker.lock:
    worker.store &=
      cookie
