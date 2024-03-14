# Package

version       = "0.1.1"
author        = "xTrayambak and Ferus authors"
description   = "A fast, independent and (hopefully) secure web browser written in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["ferus", "libferuscli"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.6.10"

# Chronicles -- logger
requires "chronicles >= 0.10.3"

# Jsony -- JSON encode/decode for IPC layer
requires "jsony >= 1.1.5"

# Netty -- low latency reliable UDP implementation
requires "netty >= 0.2.1"

# Weave -- threading abstraction (ringabout's fork)
# requires "https://github.com/ringabout/weave"

# opengl -- OpenGL bindings for Nim
requires "opengl >= 1.2.9"

# windy -- Windowing system
requires "windy >= 0.0.0"

# boxy -- using pixie to render to an OpenGL context
requires "boxy >= 0.4.2"

# nim-taskpools -- Thread task pools
requires "taskpools >= 0.0.5"

# cligen -- CLI parser
requires "cligen >= 1.7.0"

# ferusgfx -- graphics pipeline
requires "https://github.com/ferus-web/ferusgfx >= 0.1.1"

# pretty -- pretty printer for exploring data structures
requires "pretty >= 0.1.0"

# ferus-sanchar -- new networking stack for ferus + URL parser
requires "https://github.com/ferus-web/sanchar >= 2.0.0"

# chame -- HTML5 parser
requires "https://git.sr.ht/~bptato/chame >= 0.14.4"

# chakasu -- encoding stuff
requires "https://git.sr.ht/~bptato/chakasu >= 0.3.2"

# Linux-specific modules
when defined(linux):
  requires "https://github.com/juancarlospaco/nim-firejail >= 0.5.0"

# Debug build (ferus + libferuscli)
task debugBuild, "Build Ferus as a debug package":
  exec "nim c -o:bin/ferus src/ferus.nim && nim c -o:bin/libferuscli src/libferuscli.nim"

# Production build (ferus + libferuscli)
task productionBuild, "Build Ferus as a production package":
  exec "nim c -o:bin/ferus -d:release src/ferus.nim && nim c -o:bin/libferuscli -d:release src/libferuscli.nim"

task quickdebug, "Build and run debug version of Ferus":
  exec "nim c -o:bin/ferus src/ferus.nim && nim c -o:bin/libferuscli src/libferuscli.nim"
  withDir "bin":
    exec "./ferus"

task buildLibferuscli, "Only re-compile libferuscli":
  echo "WARNING: You are partially recompiling libferuscli, this is intended to make development compilation fast. If you are looking to run Ferus, the commands are either nimble debugBuild or nimble productionBuild"
  exec "nim c -o:bin/libferuscli src/libferuscli.nim"
  withDir "bin":
    exec "./ferus"

task buildFerusApp, "Only re-compile Ferus app":
  echo "WARNING: You are partially recompiling Ferus, this is intended to make development compilation fast. If you are looking to run Ferus, the commands are either nimble debugBuild or nimble productionBuild"
  exec "nim c -o:bin/ferus src/ferus.nim"
  withDir "bin":
    exec "./ferus"
