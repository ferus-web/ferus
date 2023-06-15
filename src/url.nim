#[
  WIP URL parser for Ferus

  This code is licensed under the MIT license
]#

import chronicles

#[
  Basic visualization of URLs

  https://wikipedia.org/wiki/Firefox#Performance                      ---- (1)
  ^^^^^   ^^^^^^^^^^^^^ ^^^^^^^^^^^^ ^^^^^^^^^^
    |       |              |             |
  scheme  hostname      path         fragment

  https://api.freecookies.in/getuserbyuname?name=thatoneferususer     ---- (2)
  [E  X  P  L  A  I  N  E  D  A  B  O  V  E]^^^^^^^^^^^^^^^^^^^^^^
                                                     |
                                                   query
  This type contains everything necessary to create a URL compliant to the WHATWG URL Living Standard
]#
type FerusURL* = ref object of RootObj
  scheme*: string
  hostname*: string
  port*: int
  username*: string
  password*: string
  query*: string
  fragment*: string
  path*: string
  baseUrl*: bool