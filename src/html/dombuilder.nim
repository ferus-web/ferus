import std/[streams, options, tables], chronicles, 
       chame/[htmlparser, tags],
       chakasu/charset,
       ferus_sanchar/url

type
  Node* = ref object of RootObj
    nodeType*: NodeType
    childList*: seq[Node]
    parentNode*: Node
    root: Node
    document*: Document
    index*: int

  Attribute* = ref object of Node
    namespaceURI*: string
    prefix*: string
    localName*: string
    value*: string
    ownerElement*: string

  CharacterData* = ref object of Node
    data*: string

  Comment* = ref object of CharacterData
  
  Document* = ref object of Node
    url*: URL
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
    localName*: string
    namespace*: Namespace
    attrs*: Table[string, string]
    prefix*: string
    

  FerusDOMBuilder* = ref object of DOMBuilder[Node]

proc dump*(document: Document) =
  echo "woohoo"

template getDocument(domBuilder: FerusDOMBuilder): Document =
  cast[Document](domBuilder.document)

proc finish*(builder: DOMBuilder[Node]) =
  let 
    builder = cast[FerusDOMBuilder](builder)
    document = builder.getDocument()

  info "[src/html/htmldom.nim] FerusDOMBuilder has reached finish()"

proc parseError(builder: DOMBuilder[Node], message: string) =
  error "[src/html/htmldom.nim] An error occured during DOM parsing."
  echo "* " & message

proc getParentNode(builder: DOMBuilder[Node], handle: Node): Option[Node] =
  return option(handle.parentNode)

proc getTagType(builder: DOMBuilder[Node], handle: Node): TagType =
  return Element(handle).tagType

proc getLocalName(builder: DOMBuilder[Node], handle: Node): string =
  return Element(handle).localName

proc getNamespace(builder: DOMBuilder[Node], handle: Node): Namespace =
  return Element(handle).namespace

proc createElement(builder: DOMBuilder[Node], localName: string,
    namespace: Namespace, tagType: TagType,
    attrs: Table[string, string]): Node =
  let builder = cast[FerusDOMBuilder](builder)
  let element = Element(
    nodeType: ELEMENT_NODE,
    localName: localName,
    namespace: namespace,
    tagType: tagType,
    attrs: attrs
  )
  return element

proc createComment(builder: DOMBuilder[Node], text: string): Node =
  return Comment(nodeType: COMMENT_NODE, data: text)

proc createDocumentType(builder: DOMBuilder[Node], name, publicId,
    systemId: string): Node =
  return DocumentType(nodeType: DOCUMENT_TYPE_NODE, name: name, publicId: publicId,
    systemId: systemId)

func countChildren(node: Node, nodeType: NodeType): int =
  for child in node.childList:
    if child.nodeType == nodeType:
      inc result

func hasChild(node: Node, nodeType: NodeType): bool =
  for child in node.childList:
    if child.nodeType == nodeType:
      return true

func isHostIncludingInclusiveAncestor(a, b: Node): bool =
  var b = b
  while b != nil:
    if b == a:
      return true
    b = b.parentNode

func hasPreviousSibling(node: Node, nodeType: NodeType): bool =
  for n in node.parentNode.childList:
    if n == node:
      break
    if n.nodeType == nodeType:
      return true
  return false

func hasNextSibling(node: Node, nodeType: NodeType): bool =
  for i in countdown(node.parentNode.childList.len, 0):
    let n = node.parentNode.childList[i]
    if n == node:
      break
    if n.nodeType == nodeType:
      return true
  return false

proc moveChildren(builder: DOMBuilder[Node], fromNode, toNode: Node) =
  var tomove = fromNode.childList
  # for node in tomove:
    # node.remove(suppressObservers = true)
  # for child in tomove:
    # toNode.insert(child, nil)

# WARNING the ordering of the arguments in the standard is whack so this
# doesn't match that
func preInsertionValidity*(parent, node, before: Node): bool =
  if parent.nodeType notin {DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE}:
    return false
  if node.isHostIncludingInclusiveAncestor(parent):
    return false
  if before != nil and before.parentNode != parent:
    return false
  if node.nodeType notin {DOCUMENT_FRAGMENT_NODE, DOCUMENT_TYPE_NODE,
      ELEMENT_NODE} + CharacterDataNodes:
    return false
  if node.nodeType == TEXT_NODE and parent.nodeType == DOCUMENT_NODE:
    return false
  if node.nodeType == DOCUMENT_TYPE_NODE and parent.nodeType != DOCUMENT_NODE:
    return false
  if parent.nodeType == DOCUMENT_NODE:
    case node.nodeType
    of DOCUMENT_FRAGMENT_NODE:
      let elems = node.countChildren(ELEMENT_NODE)
      if elems > 1 or node.hasChild(TEXT_NODE):
        return false
      elif elems == 1 and (parent.hasChild(ELEMENT_NODE) or
          before != nil and (before.nodeType == DOCUMENT_TYPE_NODE or
          before.hasNextSibling(DOCUMENT_TYPE_NODE))):
        return false
    of ELEMENT_NODE:
      if parent.hasChild(ELEMENT_NODE):
        return false
      elif before != nil and (before.nodeType == DOCUMENT_TYPE_NODE or
            before.hasNextSibling(DOCUMENT_TYPE_NODE)):
        return false
    of DOCUMENT_TYPE_NODE:
      if parent.hasChild(DOCUMENT_TYPE_NODE) or
          before != nil and before.hasPreviousSibling(ELEMENT_NODE) or
          before == nil and parent.hasChild(ELEMENT_NODE):
        return false
    else: discard
  return true # no exception reached

proc insertBefore(builder: DOMBuilder[Node], parent, child, before: Node) =
  if parent.preInsertionValidity(child, before):
    if before == nil:
      parent.childList.add(child)
    else:
      let i = parent.childList.find(before)
      parent.childList.insert(child, i)
    child.parentNode = parent

proc insertText(builder: DOMBuilder[Node], parent: Node, text: string,
    before: Node) =
  let prevSibling = if before != nil:
    parent.childList[parent.childList.find(before) - 1]
  elif parent.childList.len > 0:
    parent.childList[^1]
  else:
    nil
  if prevSibling != nil and prevSibling.nodeType == TEXT_NODE:
    Text(prevSibling).data &= text
  else:
    let text = Text(nodeType: TEXT_NODE, data: text)
    insertBefore(builder, parent, text, before)

proc remove(builder: DOMBuilder[Node], child: Node) =
  if child.parentNode != nil:
    let i = child.parentNode.childList.find(child)
    child.parentNode.childList.delete(i)
    child.parentNode = nil

proc addAttrsIfMissing(builder: DOMBuilder[Node], element: Node,
    attrs: Table[string, string]) =
  let element = Element(element)
  for k, v in attrs:
    if k notin element.attrs:
      element.attrs[k] = v

proc newFerusDOMBuilder*: FerusDOMBuilder =
  let document = Document(nodeType: DOCUMENT_NODE)
  return FerusDOMBuilder(
    document: document,
    finish: finish,
    getTagType: getTagType,
    getParentNode: getParentNode,
    getLocalName: getLocalName,
    getNamespace: getNamespace,
    createElement: createElement,
    createComment: createComment,
    createDocumentType: createDocumentType,
    insertBefore: insertBefore,
    insertText: insertText,
    remove: remove,
    addAttrsIfMissing: addAttrsIfMissing,
    moveChildren: moveChildren
  )

