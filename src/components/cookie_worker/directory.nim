## Simply specifies where Ferus caches data.
import std/[os]

proc getBaseDirectory*: string {.inline.} =
  let base = getHomeDir() / ".ferus"

  if not dirExists(base):
    createDir(base)

  base

proc getCookiesPath*: string {.inline.} =
  getBaseDirectory() / "cookies.bin"
