# Package

version = "0.2.4"
author = "xTrayambak"
description = "The Ferus Web Engine"
license = "GPL3"
srcDir = "src"
backend = "cpp"
bin = @["ferus", "ferus_process"]

# Dependencies

requires "nim >= 2.0.2"
requires "ferusgfx >= 1.2.1"
requires "colored_logger >= 0.1.0"
requires "stylus >= 0.1.3"
requires "https://github.com/ferus-web/sanchar >= 2.0.2"
requires "https://git.sr.ht/~bptato/chame >= 1.0.1"
requires "seccomp >= 0.2.1"
requires "simdutf >= 5.5.0"
requires "https://github.com/ferus-web/bali#master"
requires "results >= 0.5.0"
requires "pretty >= 0.1.0"
requires "jsony >= 1.1.5"
requires "chagashi >= 0.5.4"
requires "curly >= 1.1.1"
requires "webby >= 0.2.1"
requires "waterpark >= 0.1.7"
requires "chroma >= 0.2.7"
requires "bumpy >= 1.1.2"
requires "glfw >= 3.4.0.4"
requires "whisky >= 0.1.3"
requires "npeg >= 1.3.0"
requires "webidl2nim >= 0.0.1"

task niskriya, "Build Niskriya, the WebIDL to Nim source generator":
  exec "nim c --define:release --out:niskriya tools/niskriya.nim"
