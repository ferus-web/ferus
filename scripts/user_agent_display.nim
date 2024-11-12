# requires: mummy

import std/strutils
import mummy, mummy/routers

proc indexHandler(request: Request) =
  echo "Request from client"
  echo "User Agent: " & request.headers["User-Agent"]
  echo "Address: " & request.remoteAddress
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  let content = """
<!DOCTYPE html>
<html>
  <head>
    <title>Ferus User Agent Displayer</title>
  </head>
  <body>
    <script>
      console.log(document.baseURI)
    </script>
    <h1>$1</h1>
  </body>
</html>
  """ % [request.headers["User-Agent"]]
  request.respond(200, headers, content)

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
