import os
import parsers/css/css
import chronicles

proc getFlagAt(idx: int): string =
  if idx > paramCount():
    error "[src/libferuscli.nim] getFlagAt() failed, idx > os.paramCount()"
    ""
  
  paramStr(idx)


proc main =
  var initialFlag = getFlagAt(0)
  if initialFlag.len < 1:
    error "[src/libferuscli.nim] Expected arguments, got none."
    quit()
  
  var cssParser = newCSSParser()
