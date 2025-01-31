import std/[os, logging, options], ferus_ipc/client/prelude

var client = newIPCClient()
# client.broadcastVersion("0.1.0")
client.identifyAs(
  FerusProcess(worker: false, pid: getCurrentProcessId().uint64, group: 0)
)

client.onConnect = proc() =
  info "We're connected!"

client.onError = proc(error: FailedHandshakeReason) =
  case error
  of fhInvalidVersion:
    quit "Invalid version"
  else:
    discard

let path = client.connect()

client.handshake()
addHandler newIPCLogger(lvlAll, client)

while true:
  var location =
    DataLocation(kind: DataLocationKind.WebRequest, url: "totallyrealwebsite.xyz")
  let value = client.requestDataTransfer(ResourceRequired, location)
    # block until we are handed over the resource (or an error)

  echo value.get.data

# no need to call `client.close()`, ORC manages that for you ;)
