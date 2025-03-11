## Niskriya is Ferus' WebIDL to Nim generator
## Usage: niskriya [path to file] [output file]
import std/[os, logging, sequtils, deques]
import components/idl/baligen, components/argparser
import pkg/[colored_logger, webidl2nim, jsony, pretty]

proc showHelp() =
  echo """
Niskriya is Ferus' WebIDL to Nim code generator.

Usage: niskriya [path to IDL file] [output destination]

Flags:
  --dump-tree, -D             Dump the WebIDL source tree
  --verbose, -v               Get more verbose log messages
"""
  quit(0)

proc main() =
  setLogFilter(lvlInfo)
  addHandler(newColoredLogger())

  var input = parseInput()
  if input.enabled("help", "h"):
    showHelp()

  if input.enabled("verbose", "v"):
    setLogFilter(lvlAll)

  if input.arguments.len < 2:
    error "niskriya: expected atleast 2 arguments, got none."
    error "niskriya: run --help for more information."
    quit(1)

  let
    source = input.arguments[0]
    destination = input.arguments[1]

  if not fileExists(source):
    error "niskriya: no such file exists: " & source
    quit(1)

  let content =
    try:
      readFile(source)
    except OSError as exc:
      error "niskriya: whilst reading source file: " & exc.msg
      quit(1)
      newString(0)

  let tokens = tokenize(patchSource(content))
  debug "niskriya: tokenized source into " & $tokens.len & " tokens."

  let tree = parseCode(tokens).stack.toSeq()
  if input.enabled("dump-tree", "D"):
    print(tree)
    quit(0)

  debug "niskriya: generating Bali wrapper"
  let wrapper = generateBaliWrapper(tree)

  try:
    writeFile(destination, wrapper & '\n')
  except OSError as exc:
    error "niskriya: failed to write to destination: " & exc.msg

when isMainModule:
  main()
