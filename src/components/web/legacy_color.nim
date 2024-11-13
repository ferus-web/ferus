## Legacy color parser
import std/[strutils, options, logging]
import pkg/bali/internal/trim_string
import pkg/chroma
import ../shared/sugar

proc parseLegacyColorValue*(str: string): Option[Color] =
  if str.len < 2:
    return

  var input = str.internalTrim(strutils.Whitespace, TrimMode.Both)
  if input.toLowerAscii() == "transparent":
    return
  
  try:
    return chroma.parseHex(str[1 ..< str.len]).some()
  except chroma.InvalidColor as exc:
    warn "parseLegacyColorValue(" & str & "): chroma raised an error whilst parsing hex string: " & exc.msg
