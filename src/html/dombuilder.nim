import std/[streams, options, tables, hashes, sets], 
       chronicles, 
       chame/[htmlparser, tags],
       chakasu/charset,
       sanchar/parse/url

# All of this new code is borrowed from the minidom implementation :P
const FAtomFactoryStrMapLength = 1024 # must be a power of 2
static:
  doAssert (FAtomFactoryStrMapLength and (FAtomFactoryStrMapLength - 1)) == 0

type
  FAtom* = distinct int

  FAtomFactory* = ref object of RootObj
    strMap: array[FAtomFactoryStrMapLength, seq[FAtom]]
    atomMap: seq[string]

# Mandatory Atom functions
func `==`*(a, b: FAtom): bool {.borrow.}
func hash*(atom: FAtom): Hash {.borrow.}

func strToAtom*(factory: FAtomFactory, s: string): FAtom

proc newFAtomFactory*(): FAtomFactory =
  const minCap = int(TagType.high) + 1
  let factory = FAtomFactory(
    atomMap: newSeqOfCap[string](minCap),
  )
  factory.atomMap.add("") # skip TAG_UNKNOWN
  for tagType in TagType(int(TAG_UNKNOWN) + 1) .. TagType.high:
    discard factory.strToAtom($tagType)
  return factory

func strToAtom*(factory: FAtomFactory, s: string): FAtom =
  let h = s.hash()
  let i = h and (factory.strMap.len - 1)
  for atom in factory.strMap[i]:
    if factory.atomMap[int(atom)] == s:
      # Found
      return atom
  # Not found
  let atom = FAtom(factory.atomMap.len)
  factory.atomMap.add(s)
  factory.strMap[i].add(atom)
  return atom

func tagTypeToAtom*(factory: FAtomFactory, tagType: TagType): FAtom =
  assert tagType != TAG_UNKNOWN
  return FAtom(tagType)

func atomToStr*(factory: FAtomFactory, atom: FAtom): string =
  return factory.atomMap[int(atom)]

type
  Node* = ref object of RootObj
    childList*: seq[Node]
    parentNode* {.cursor.}: Node
    root: Node
    document*: Document
    index*: int

  Attribute* = ParsedAttr[FAtom]

  CharacterData* = ref object of Node
    data*: string

  Comment* = ref object of CharacterData
  
  Document* = ref object of Node
    url*: URL
    factory*: FAtomFactory
    mode*: QuirksMode

  Text* = ref object of CharacterData

  CDATASection = ref object of CharacterData

  ProcessingInstruction = ref object of CharacterData
    target: string

  DocumentType* = ref object of Node
    name*: string
    publicId*: string
    systemId*: string

  Element* = ref object of Node
    tagType*: TagType
    localName*: FAtom
    namespace*: Namespace
    attrs*: seq[Attribute]

  FerusDOMBuilder* = ref object of DOMBuilder[Node, FAtom]
    document*: Document
    factory*: FAtomFactory

  DocumentFragment* = ref object of Node

  HTMLTemplateElement* = ref object of Element
    content*: DocumentFragment

  DOMBuilderImpl = FerusDOMBuilder
  AtomImpl = FAtom
  HandleImpl = Node

func toTagType*(atom: FAtom): TagType {.inline.} =
  if int(atom) <= int(high(TagType)):
    return TagType(atom)
  return TAG_UNKNOWN

func tagType*(element: Element): TagType =
  return #element.localName.toTagType()

func cmp*(a, b: FAtom): int {.inline.} =
  return cmp(int(a), int(b))

# We use this to validate input strings, since htmltokenizer/htmlparser does no
# input validation.
proc toValidUTF8(s: string): string =
  result = ""
  var i = 0
  while i < s.len:
    if int(s[i]) < 0x80:
      result &= s[i]
      inc i
    elif int(s[i]) shr 5 == 0x6:
      if i + 1 < s.len and int(s[i + 1]) shr 6 == 2:
        result &= s[i]
        result &= s[i + 1]
      else:
        result &= "\uFFFD"
      i += 2
    elif int(s[i]) shr 4 == 0xE:
      if i + 2 < s.len and int(s[i + 1]) shr 6 == 2 and
          int(s[i + 2]) shr 6 == 2:
        result &= s[i]
        result &= s[i + 1]
        result &= s[i + 2]
      else:
        result &= "\uFFFD"
      i += 3
    elif int(s[i]) shr 3 == 0x1E:
      if i + 3 < s.len and int(s[i + 1]) shr 6 == 2 and
          int(s[i + 2]) shr 6 == 2 and int(s[i + 3]) shr 6 == 2:
        result &= s[i]
        result &= s[i + 1]
        result &= s[i + 2]
        result &= s[i + 3]
      else:
        result &= "\uFFFD"
      i += 4
    else:
      result &= "\uFFFD"
      inc i

proc localNameStr*(element: Element): string =
  return #element.document.factory.atomToStr(element.localName)

iterator attrsStr*(element: Element): tuple[name, value: string] =
  let factory = element.document.factory
  for attr in element.attrs:
    var name = ""
    if attr.prefix != NO_PREFIX:
      name &= $attr.prefix & ':'
    name &= factory.atomToStr(attr.name)
    yield (name, attr.value)

# htmlparseriface implementation
include chame/htmlparseriface
proc strToAtomImpl(builder: FerusDOMBuilder, s: string): FAtom =
  return builder.factory.strToAtom(s)

proc tagTypeToAtomImpl(builder: FerusDOMBuilder, tagType: TagType): FAtom =
  return builder.factory.tagTypeToAtom(tagType)

proc atomToTagTypeImpl(builder: FerusDOMBuilder, atom: FAtom): TagType =
  return atom.toTagType()

proc getDocumentImpl(builder: FerusDOMBuilder): Node =
  return builder.document

proc getParentNodeImpl(builder: FerusDOMBuilder, handle: Node): Option[Node] =
  return none(Node)#option(handle.parentNode)

proc createElement(document: Document, localName: FAtom, namespace: Namespace):
    Element =
  let element = if localName.toTagType() == TAG_TEMPLATE and
      namespace == Namespace.HTML:
    HTMLTemplateElement(
      content: DocumentFragment()
    )
  else:
    Element()
  element.localName = localName
  element.namespace = namespace
  element.document = document
  return element

proc createHTMLElementImpl(builder: FerusDOMBuilder): Node =
  let localName = builder.factory.tagTypeToAtom(TAG_HTML)
  return builder.document.createElement(localName, Namespace.HTML)

proc createElementForTokenImpl(builder: FerusDOMBuilder, localName: FAtom,
    namespace: Namespace, intendedParent: Node, htmlAttrs: Table[FAtom, string],
    xmlAttrs: seq[Attribute]): Node =
  let element = builder.document.createElement(localName, namespace)
  element.attrs = xmlAttrs
  for k, v in htmlAttrs:
    element.attrs.add((NO_PREFIX, NO_NAMESPACE, k, v.toValidUTF8()))
  # element.attrs.sort(func(a, b: Attribute): int = cmp(a.name, b.name))
  return element

proc getLocalNameImpl(builder: FerusDOMBuilder, handle: Node): FAtom =
  return Element(handle).localName

proc getNamespaceImpl(builder: FerusDOMBuilder, handle: Node): Namespace =
  return Element(handle).namespace

proc getTemplateContentImpl(builder: FerusDOMBuilder, handle: Node): Node =
  return HTMLTemplateElement(handle).content

proc createCommentImpl(builder: FerusDOMBuilder, text: string): Node =
  return Comment(data: text.toValidUTF8())

proc createDocumentTypeImpl(builder: FerusDOMBuilder, name, publicId,
    systemId: string): Node =
  return DocumentType(
    name: name.toValidUTF8(),
    publicId: publicId.toValidUTF8(),
    systemId: systemId.toValidUTF8()
  )

func countElementChildren(node: Node): int =
  for child in node.childList:
    if child of Element:
      inc result

func hasTextChild(node: Node): bool =
  for child in node.childList:
    if child of Text:
      return true
  return false

func hasElementChild(node: Node): bool =
  for child in node.childList:
    if child of Element:
      return true
  return false

func hasDocumentTypeChild(node: Node): bool =
  for child in node.childList:
    if child of DocumentType:
      return true
  return false

func isHostIncludingInclusiveAncestor(a, b: Node): bool =
  var b = b
  while b != nil:
    if b == a:
      return true
    b = b.parentNode

func hasPreviousElementSibling(node: Node): bool =
  for n in node.parentNode.childList:
    if n == node:
      break
    if n of Element:
      return true
  return false

func hasNextDocumentTypeSibling(node: Node): bool =
  for i in countdown(node.parentNode.childList.len, 0):
    let n = node.parentNode.childList[i]
    if n == node:
      break
    if n of DocumentType:
      return true
  return false

func isValidParent(node: Node): bool =
  return node of Element or node of Document or node of DocumentFragment

func isValidChild(node: Node): bool =
  return node.isValidParent or node of DocumentType or node of CharacterData

# WARNING the ordering of the arguments in the standard is whack so this
# doesn't match that
func preInsertionValidity*(parent, node: Node, before: Node): bool =
  if not parent.isValidParent:
    return false
  if node.isHostIncludingInclusiveAncestor(parent):
    return false
  if before != nil and before.parentNode != parent:
    return false
  if not node.isValidChild:
    return false
  if node of Text and parent of Document:
    return false
  if node of DocumentType and not (parent of Document):
    return false
  if parent of Document:
    if node of DocumentFragment:
      let elems = node.countElementChildren()
      if elems > 1 or node.hasTextChild():
        return false
      elif elems == 1 and (parent.hasElementChild() or
          before != nil and
          (before of DocumentType or before.hasNextDocumentTypeSibling())):
        return false
    elif node of Element:
      if parent.hasElementChild():
        return false
      elif before != nil and (before of DocumentType or
            before.hasNextDocumentTypeSibling()):
        return false
    elif node of DocumentType:
      if parent.hasDocumentTypeChild() or
          before != nil and before.hasPreviousElementSibling() or
          before == nil and parent.hasElementChild():
        return false
  return true # no exception reached

proc insertBefore(parent, child: Node, before: Option[Node]) =
  let before = before.get(nil)
  if parent.preInsertionValidity(child, before):
    assert child.parentNode == nil
    if before == nil:
      parent.childList.add(child)
    else:
      let i = parent.childList.find(before)
      parent.childList.insert(child, i)
    child.parentNode = parent

proc insertBeforeImpl(builder: FerusDOMBuilder, parent, child: Node,
    before: Option[Node]) =
  parent.insertBefore(child, before)

proc insertTextImpl(builder: FerusDOMBuilder, parent: Node, text: string,
    before: Option[Node]) =
  let text = text.toValidUTF8()
  let before = before.get(nil)
  let prevSibling = if before != nil:
    let i = parent.childList.find(before)
    if i == 0:
      nil
    else:
      parent.childList[i - 1]
  elif parent.childList.len > 0:
    parent.childList[^1]
  else:
    nil
  if prevSibling != nil and prevSibling of Text:
    Text(prevSibling).data &= text
  else:
    let text = Text(data: text)
    parent.insertBefore(text, option(before))

proc removeImpl(builder: FerusDOMBuilder, child: Node) =
  if child.parentNode != nil:
    let i = child.parentNode.childList.find(child)
    child.parentNode.childList.delete(i)
    child.parentNode = nil

proc moveChildrenImpl(builder: FerusDOMBuilder, fromNode, toNode: Node) =
  let tomove = @(fromNode.childList)
  fromNode.childList.setLen(0)
  for child in tomove:
    child.parentNode = nil
    toNode.insertBefore(child, none(Node))

proc addAttrsIfMissingImpl(builder: FerusDOMBuilder, handle: Node,
    attrs: Table[FAtom, string]) =
  let element = Element(handle)
  var oldNames: HashSet[FAtom]
  for attr in element.attrs:
    oldNames.incl(attr.name)
  for name, value in attrs:
    if name notin oldNames:
      element.attrs.add((NO_PREFIX, NO_NAMESPACE, name, value.toValidUTF8()))
  # element.attrs.sort(func(a, b: Attribute): int = cmp(a.name, b.name))

method setEncodingImpl(builder: FerusDOMBuilder, encoding: string):
    SetEncodingResult {.base.} =
  # Provided as a method for minidom_cs to override.
  return SET_ENCODING_CONTINUE

template getDocument(domBuilder: FerusDOMBuilder): Document =
  cast[Document](domBuilder.document)

proc newFerusDOMBuilder*(factory: FAtomFactory): FerusDOMBuilder =
  let document = Document(factory: factory)
  FerusDOMBuilder(
    document: document,
    factory: factory
  )

proc parseHTML*(
  input: string, 
  charsets: seq[Charset] = @[],
  factory: FAtomFactory = newFAtomFactory()
): Document =
  let builder = newFerusDOMBuilder(factory)
  let opts = HTML5ParserOpts[Node, FAtom](
    isIframeSrcdoc: false,
    scripting: false
  )
  var parser = initHTML5Parser(builder, opts)
  let res = parser.parseChunk(input)

  parser.finish()

  builder.document
