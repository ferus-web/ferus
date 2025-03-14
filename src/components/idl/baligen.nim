## Convert the parsed IDL file into Nim code that binds the 
## interfaces against the Bali JavaScript engine.
## Author: Trayambak Rai (xtrayambak at disroot dot org)
import std/[strutils]
import pkg/[npeg, webidl2nim/ast]

const NimblePkgVersion {.strdefine.} = "N/A"

type FunctionDef = object
  node*: Node
  super*: string

proc patchSource*(src: string): string =
  ## "Patch" the IDL source to remove [Exposed] attributes since the parser explodes upon seeing them.
  var lines = src.splitLines()

  for line in lines:
    if line.startsWith("[Expose"):
      continue

    result &= line & '\n'

proc patchTypName*(name: string): string =
  ## "Patch" a type name to match Bali's naming scheme.
  ## The algorithm goes as follows:
  ## - `undefined`, `boolean` and other primitive types get converted into `MAtom`

  "MAtom"

proc patchViolatingIdents*(name: string): string =
  ## "Patch" an identifier to not overlap with a Nim keyword.
  ## This currently only replaces "type" with "kind".
  name.multiReplace({"type": "kind"})

proc generateBaliWrapper*(tree: seq[Node]): string =
  var source: string
  source &= "## WebIDL interface bound for Bali.\n"
  source &= "## Automatically generated by Niskriya " & NimblePkgVersion & "\n\n"

  template propDef(property: string, typHint: string = "<no type hint>") =
    source &= "  " & property & "*: JSValue    # " & typHint & '\n'

  var functions: seq[FunctionDef]

  for node in tree:
    case node.kind
    of Interface, Dictionary:
      let name = node.sons[0].strVal
      source &= "type JS" & name & "* = object"

      if node.sons[1].kind == Ident:
        # Inherited type
        source &= " of JS" & node.sons[1].strVal

      source &= '\n'

      var numProperties: uint
      for son in node.sons:
        if son.kind == DictionaryMember:
          case son.sons[0].kind
          of IdentDefs:
            # property definition
            propDef son.sons[0].sons[0].strVal, son.sons[0].sons[1].sons[0].strVal
            inc numProperties
          else:
            discard
        elif son.kind == InterfaceMember:
          case son.sons[0].kind
          of IdentDefs:
            # propery definition
            propDef son.sons[0].sons[0].strVal, son.sons[0].sons[1].sons[0].strVal
            inc numProperties
          of Operation:
            # function declaration
            functions &= FunctionDef(node: son.sons[0], super: name)
          else:
            discard

      if numProperties != 0:
        source &= '\n'
    else:
      echo "unhandled " & $node.kind

  # Now, generate functions
  for fn in functions:
    let reg = fn.node.sons[0] # RegularOperation
    let name = reg.sons[0].strVal

    # let retTyp =
    #   patchTypName(reg.sons[1].sons[0].strVal)

    source &= "proc " & name & "Impl*("
    source &= "self: JS" & fn.super & ", "
    var numArguments: uint
    for argument in reg.sons[2].sons:
      if argument.sons[0].kind == SimpleArgument:
        let argName = argument.sons[0].sons[0].sons[0].strVal.patchViolatingIdents()
          # wtf...

        if numArguments != 0:
          source &= ", "

        source &= argName & ": JSValue"
      else:
        echo "unhandled argument " & $argument.sons[0].kind

      inc numArguments

    source &= "): JSValue"
    source &= "\n"

  move(source)
