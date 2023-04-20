# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "A fast, independent and (hopefully) secure web browser written in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["ferus"]


# Dependencies

requires "nim >= 1.6.10"

requires "chronicles"
requires "jsony"
requires "netty"
