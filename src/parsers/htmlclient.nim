import chronicles, ferushtml, json, ../ipc/client

type HTMLClient* = ref object of RootObj
  ipcClient*: IPCClient
  htmlParser*: HTMLParser

proc init*(htmlClient: HTMLClient) =
  proc htmlListen(data: JSONNode) =
    echo "e"
  htmlClient.ipcClient.addReceiver(htmlListen)
