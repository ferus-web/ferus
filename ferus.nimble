# Package

version = "0.1.0"
author = "xTrayambak"
description = "The Ferus Web Engine"
license = "MIT"
srcDir = "src"
bin = @["ferus", "ferus_process"]

# Dependencies

requires "nim >= 2.0.2"
requires "ferusgfx >= 1.0.2"
requires "colored_logger >= 0.1.0"
requires "stylus >= 0.1.0"
requires "https://github.com/ferus-web/ferus_ipc"
requires "https://github.com/ferus-web/sanchar"
requires "https://github.com/ferus-web/vyavast"
requires "https://git.sr.ht/~bptato/chame >= 0.14.5"
requires "seccomp >= 0.2.1"
requires "results"
requires "pretty"
requires "glfw >= 3.4.0"
