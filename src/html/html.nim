#[
  Basic wrapper around chame

  Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import std/[charset, decoderstream], chame, chronicles

proc parseHTML*(
  src: string,
  isIframeSrcDoc: bool = false,
  scriptingEnabled: bool = true,
  canReinterpret: bool = false,
  charsets: seq[Charsets] = @[]
)
