import std/osproc

static:
  let gitHash = execCmdEx("git describe --long --dirty")
