## Tool to remove copyright string from Ferus source
## Copyr- just kidding
import std/[os, strutils]

proc main() {.inline.} =
  var files: seq[string]
  var excludeLines: seq[int]
  var x = -1

  for file in walkDirRec("src/"):
    if not fileExists(file):
      continue

    x = -1

    for line in file.readFile().splitLines():
      inc x
      if line.startsWith("## Copyright"):
        files.add(file)
        excludeLines.add(x)
        assert(files.len == excludeLines.len)
        break

  echo excludeLines

  echo "In " & $files.len & " files, found " & $excludeLines.len &
    " copyright strings that need to be purged"
  for i, file in files:
    echo "De-MITifying " & file
    var content = readFile(file).splitLines()
    content.del(excludeLines[i])

    writeFile(file, content.join("\n"))

when isMainModule:
  main()
