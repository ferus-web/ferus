# requires: mummy

import std/strutils
import mummy, mummy/routers

proc indexHandler(request: Request) =
  echo "Request from client"
  echo "User Agent: " & request.headers["User-Agent"]
  echo "Address: " & request.remoteAddress
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  let content =
    """
<!DOCTYPE html>
<html>
  <head>
    <title>Ferus User Agent Displayer</title>
  </head>
  <body>
    <link rel="stylesheet" href="style.css"></style>
    <script>
      console.log(document.baseURI)
    </script>
    <h1>$1</h1>
  </body>
</html>
  """ %
    [request.headers["User-Agent"]]
  request.respond(200, headers, content)

proc styleHandler(request: Request) =
  echo "Request for network stylesheet"

  var headers: HttpHeaders
  headers["Content-Type"] = "text/css"
  request.respond(
    200, headers,
    """
h1 {
  font-size: 64px;
}
    """,
  )

var router: Router
router.get("/", indexHandler)
router.get("/style.css", styleHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
