import std/options
import ./document
import ../../web/dom
import sanchar/proto/http/shared, ferus_ipc/shared

type
  ParseHTMLPacket* = ref object
    kind: FerusMagic = feParserParse
    source*: string

  HTMLParseError* {.pure.} = enum
    None
    MalformedJSONPayload

  HTMLParseResult* = ref object
    kind: FerusMagic = feHtmlParserResult
    failed*: bool = false
    error*: HTMLParseError = HTMLParseError.None
    document*: Option[HTMLDocument]
