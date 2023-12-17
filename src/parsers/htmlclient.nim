import marshal, chronicles, ferushtml, tables, json, ../ipc/[client, constants]

type HTMLClient* = ref object of RootObj
  ipcClient*: IPCClient
  htmlParser*: HTMLParser

proc init*(htmlClient: HTMLClient) =
  proc htmlListen(data: JSONNode) =
    if "result" in data:
      let res = data["result"]
      if res == IPC_CLIENT_DO_HTML_PARSE:
        info "[src/parsers/htmlclient.nim] Parsing HTML"
        let output = $$htmlClient.htmlParser.parseToDocument(
          data["payload"]
        )
        htmlClient.ipcClient.send({
          "result": IPC_CLIENT_RESULT_HTML_PARSE,
          "payload": output
        }.toTable)
      
  htmlClient.ipcClient.addReceiver(htmlListen)
