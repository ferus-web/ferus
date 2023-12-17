import std/[tables, streams]
import chakasu/[charset, decoderstream], chame/[tags, htmlparser], dombuilder

proc parseHTML*(inputStream: Stream,
    charsets: seq[Charset] = @[], canReinterpret = true): Document =
  let builder = newFerusDOMBuilder()
  let opts = HTML5ParserOpts[Node](
    isIframeSrcdoc: false,
    scripting: false,
    canReinterpret: canReinterpret,
    charsets: charsets
  )
  parseHTML(inputStream, builder, opts)
  return Document(builder.document)

proc parseHTML*(
  inputStream: string, 
  charsets: seq[Charset] = @[], 
  canReinterpret = true
): Document =
  let builder = newFerusDOMBuilder()
  let opts = HTML5ParserOpts[Node](
    isIframeSrcdoc: false,
    scripting: false,
    canReinterpret: canReinterpret,
    charsets: charsets
  )
  parseHTML(
    newStringStream(inputStream),
    builder, opts
  )
