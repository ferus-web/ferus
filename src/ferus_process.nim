import std/logging
import colored_logger

when defined(linux):
  import components/sandbox/linux

proc main {.inline.} =
  addHandler newColoredLogger()
  sandbox()
 
when isMainModule:
  main()
