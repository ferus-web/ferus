# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "The Ferus Web Engine"
license       = "MIT"
srcDir        = "src"
bin           = @["ferus", "ferus_process"]


# Dependencies

requires "nim >= 2.0.2"
requires "ferusgfx >= 1.0.0"
requires "colored_logger >= 0.1.0"
requires "https://github.com/ferus-web/ferus_ipc"
requires "https://github.com/ferus-web/sanchar"
requires "https://github.com/ferus-web/vyavast"
requires "seccomp >= 0.2.1"
