import std/[logging, tables]
import ../parsers/html/document
import bali/runtime/prelude
import chagashi/charset
import sanchar/parse/url
import pretty

type JSDocument* = object
  baseURI*: string
  domain*: string
  characterSet*: string

proc generateIR*(runtime: Runtime) =
  debug "components/web/document: generating interfaces"
  runtime.registerType("document", JSDocument)

proc updateDocumentState*(runtime: Runtime, document: HTMLDocument) =
  debug "components/web/document: document has been updated, updating internal state"
  runtime.setProperty(JSDocument, "baseURI", str($document.url))
  runtime.setProperty(JSDocument, "domain", str(document.url.hostname()))
  runtime.setProperty(JSDocument, "characterSet", str($document.encoding))
  runtime.setProperty(JSDocument, "charset", str($document.encoding))
