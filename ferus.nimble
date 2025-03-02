# Package

version = "0.2.3"
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
requires "stylus >= 0.1.1"
requires "https://github.com/ferus-web/sanchar >= 2.0.2"
requires "https://git.sr.ht/~bptato/chame >= 1.0.1"
requires "seccomp >= 0.2.1"
requires "simdutf >= 5.5.0"
requires "https://github.com/ferus-web/bali >= 0.6.3"
requires "results >= 0.5.0"
requires "pretty >= 0.1.0"
requires "jsony >= 1.1.5"
requires "chagashi >= 0.5.4"
requires "curly >= 1.1.1"
requires "webby >= 0.2.1"

when defined(ferusUseGlfw):
  requires "glfw >= 3.4.0.4"
else:
  requires "windy >= 0.0.0"

requires "waterpark >= 0.1.7"
