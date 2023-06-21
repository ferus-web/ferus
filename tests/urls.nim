# src/net/url.nim testing
import ../src/net/url

var p = newURLParser("https://github.com")
discard p.parse()