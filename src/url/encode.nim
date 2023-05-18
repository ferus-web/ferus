import std/encodings

proc toUtf8*(content: string): string =
  convert(content, "CP1252", "UTF-8")
