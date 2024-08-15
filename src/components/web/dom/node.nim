type
  NodeKind* = enum
    nkInvalid
    nkElement
    nkAttribute
    nkText
    nkCdataSection
    nkEntityRef
    nkEntity
    nkProcessingInstruction
    nkComment
    nkDocument
    nkDocumentType
    nkDocumentFragment
    nkNotation

  NameOrDescription* = enum
    Name
    Description

  GetRootNodeOptions* = object
    composed*: bool

  FragmentSerializationNode* = enum
    Inner
    Outer

  Node* = object
