import std/[options, sequtils, strutils, times]
import ./cookie
import ../../shared/[sugar, parse_ints]

type
  ParsedCookie* = object
    name*, value*: string
    sameSiteAttribute*: SameSite = ssDefault

    expiryTimeFromExpiresAttribute*: Option[DateTime]
    expiryTimeFromMaxAgeAttribute*: Option[DateTime]

    domain*, path*: Option[string]

    secureAttributePresent*, httpOnlyAttributePresent*: bool = false

const
  MaxCookieSize {.intdefine: "WebMaxCookieSize".} = 4096
  ShortMonthNames = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

{.push checks: off, inline.}
proc find(haystack: string, needle: char, ignores: seq[int] = @[]): Option[int] =
  for i, c in haystack:
    if i in ignores: continue

    if c == needle:
      return some(i)
{.pop.}

proc parseDateTime*(value: string): Option[DateTime] {.inline.} =
  var hour, minute, second, dayOfMonth, month, year: uint

  proc toUint(token: string, res: var uint): bool {.inline.} =
    try:
      res = parseUint(token)
      true
    except ValueError:
      false
  
  proc parseTime(token: string): bool =
    let parts = token.split(':')
    if parts.len < 3:
      return false

    for part in parts:
      if part.len < 2:
        return false

    toUint(parts[0], hour) and toUint(parts[1], minute) and toUint(parts[2], hour)

  proc parseDayOfMonth(token: string): bool =
    if token.len < 2:
      return false

    toUint(token, dayOfMonth)

  proc parseMonth(token: string): bool =
    for i in 0 ..< 12:
      if token.toLowerAscii() == ShortMonthNames[i]:
        month = (i + 1).uint
        return true

    false

  proc parseYear(token: string): bool =
    if token.len != 2 and token.len != 4:
      false
    else:
      toUint(token, year)

  proc isDelim(c: char): bool {.inline.} =
    c == '\t' or
    c >= ' ' and c <= '/' or
    c >= ';' and c <= '@' or
    c >= '[' and c <= '`' or
    c >= '{' and c <= '~'

  var
    foundTime = false
    foundDayOfMonth = false
    foundMonth = false
    foundYear = false

  let dateTokens = block:
    var
      curr: string
      s: seq[string]
    
    for i, c in value:
      if not c.isDelim():
        curr &= c
      else:
        curr.removePrefix(' ') # FIXME: dumb, awful, pungent, disgusting, crappy and very bad way to fix this, fix it!
        s &= curr
        curr = "" & c
    
    s
 
  for dateTok in dateTokens:
    if not foundTime and parseTime(dateTok):
      foundTime = true
    elif not foundDayOfMonth and parseDayOfMonth(dateTok):
      foundDayOfMonth = true
    elif not foundMonth and parseMonth(dateTok):
      foundMonth = true
    elif not foundYear and parseYear(dateTok):
      foundYear = true

  if year >= 70 and year <= 99:
    year += 1900

  if year <= 69:
    year += 2000
  
  if not foundTime or 
    not foundDayOfMonth or
    not foundMonth or
    not foundYear:
    return
  
  # Perform some sanity checks to ensure that some values don't go beyond their intended ranges
  if dayOfMonth < 1 and dayOfMonth > 31:
    return

  if year < 1601:
    return

  if hour > 23:
    return

  if minute > 59:
    return

  if second > 59:
    return

  if dayOfMonth > getDaysInMonth(month.Month, year.int).uint:
    return

  some dateTime(year.int, month.Month, dayOfMonth.int, hour.int, minute.int, second.int, 0, local())

proc onExpiresAttribute*(cookie: var ParsedCookie, value: string) {.inline.} =
  if (let expiryTime = parseDateTime(value); *expiryTime):
    cookie.expiryTimeFromExpiresAttribute = some &expiryTime

proc onMaxAgeAttribute*(cookie: var ParsedCookie, value: string) {.inline.} =
  if value.len < 1 or value[0] notin Digits and value[0] != '-':
    return

  if (let deltaSeconds = value.tryParseInt(); *deltaSeconds):
    if &deltaSeconds <= 0:
      cookie.expiryTimeFromMaxAgeAttribute = some(dateTime(1970, mJan, 1)) # January 1st, 1970
    else:
      cookie.expiryTimeFromMaxAgeAttribute = some(now() + seconds(&deltaSeconds))

proc onDomainAttribute*(cookie: var ParsedCookie, value: string) {.inline.} =
  if value.len < 1:
    return

  var domain: string

  if value[0] == '.':
    domain = value[1 ..< value.len]
  else:
    domain = value

  cookie.domain = some(domain)

proc onPathAttribute*(cookie: var ParsedCookie, value: string) {.inline.} =
  if value.len < 1 or value[0] != '/':
    return

  cookie.path = some(value)

proc onSecureAttribute*(cookie: var ParsedCookie) {.inline.} =
  cookie.secureAttributePresent = true

proc onHttpOnlyAttribute*(cookie: var ParsedCookie) {.inline.} =
  cookie.httpOnlyAttributePresent = true

proc onSameSiteAttribute*(cookie: var ParsedCookie, value: string) {.inline.} =
  cookie.sameSiteAttribute = sameSite(value)

proc processAttributes*(cookie: var ParsedCookie, name, value: string) =
  case name.toLowerAscii()
  of "expires":
    onExpiresAttribute(cookie, value)
  of "max-age":
    onMaxAgeAttribute(cookie, value)
  of "domain":
    onDomainAttribute(cookie, value)
  of "path":
    onPathAttribute(cookie, value)
  of "secure":
    onSecureAttribute(cookie)
  of "httponly":
    onHttpOnlyAttribute(cookie)
  of "samesite":
    onSameSiteAttribute(cookie, value)

proc parseAttributes*(cookie: var ParsedCookie, input: string) =
  # If the unparsed input section is empty, don't bother going ahead.
  if input.len < 1:
    return

  # Discard the first character of the input as it will be a semicolon
  var input = input[1 ..< input.len]

  var cookieAv: string
  if (let position = input.find(';'); *position):
    cookieAv = input[0 ..< &position]
    input = input[&position + 1 ..< input.len]
  else:
    cookieAv = input
    input.reset()

  var attrName, attrVal: string
  if (let position = cookieAv.find('='); *position):
    attrName = cookieAv[0 ..< &position]
    
    if &position < cookieAv.len - 1:
      attrVal = cookieAv[&position + 1 ..< cookieAv.len]
  else:
    attrName = cookieAv
  
  for c in Whitespace:
    attrName.removePrefix(c)
    attrName.removeSuffix(c)
    
    attrVal.removePrefix(c)
    attrVal.removeSuffix(c)
  
  # echo attrName & " = " & attrVal
  processAttributes(cookie, attrName, attrVal)
  parseAttributes(cookie, input)

proc parseCookie*(input: string): Option[ParsedCookie] {.inline.} =
  if input.len > MaxCookieSize:
    return

  var nameValuePair, unparsedAttrs: string

  if (let position = input.find(';'); *position):
    # The name-value pair must be a slice from the start to the position at which the `;` symbol is found but it mustn't include the semicolon itself.
    # The unparsed attributes will be the rest of the string, excluding the semicolon itself.
    nameValuePair = input[0 ..< &position]
    unparsedAttrs = input[&position + 1 ..< input.len]
  else:
    nameValuePair = input.deepCopy()

  var name, value: string

  if (let position = input.find('='); *position):
    name = nameValuePair[0 ..< &position]

    if &position < nameValuePair.len - 1:
      value = nameValuePair[&position + 1 ..< nameValuePair.len]
  else:
    # If the name value pair lacks a `=`, ignore the cookie entirely.
    return
  
  # Remove any trailing whitespace from the name and value
  name = cast[string](
    name.filterIt(
      it notin Whitespace
    )
  )
  
  value = cast[string](
    value.filterIt(
      it notin Whitespace
    )
  )
  
  # If the name's empty, ignore the cookie entirely.
  if name.len < 1:
    return
  
  var parsed = ParsedCookie(
    name: name,
    value: value
  )

  parseAttributes(parsed, unparsedAttrs)
  parsed.some()

export cookie
