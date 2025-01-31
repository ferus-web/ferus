import std/[logging, options]
import colored_logger
import ferus_ipc/server/prelude
import jsony

let logger = newColoredLogger()
addHandler logger

var server = newIPCServer()

server.add(FerusGroup())

server.initialize() # optionally, provide a path as `Option[string]`
server.onConnection = proc(process: FerusProcess) =
  echo "yippee"

# Block until a new connection is made
server.acceptNewConnection()

server.onDataTransfer = proc(process: FerusProcess, request: DataTransferRequest) =
  echo "acting on data transfer"

  server.send(process.socket, DataTransferResult(success: true, data: "verycoolindeed"))

while true:
  server.receiveFrom(0, 0)
  server.poll()
