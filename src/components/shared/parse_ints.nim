import std/[options, strutils]

proc tryParseInt*(s: string): Option[int] {.inline.} =
  try:
    parseInt(s).some()
  except ValueError:
    none(int)
