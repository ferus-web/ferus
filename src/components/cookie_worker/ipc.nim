import std/options
import ../web/cookie/parsed_cookie
import ferus_ipc/shared

type
  CookieWorkerStore* = ref object
    kind: FerusMagic = feCookieWorkerStore
    cookie*: ParsedCookie
