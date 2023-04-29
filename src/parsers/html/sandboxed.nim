#[
  Sandboxed HTML parser. This is the one to be used when dealing with 
  unsafe/untrusted data. If a vulnerability exists which allows for a takeover,
  then it will be rendered futile (sorry for the pun) since this process is
  isolated by the Policyman sandbox policies.

  This code is licensed under the MIT license
]#

import tables
import html, ../../ipc/client, ../../ipc/constants


type SandboxedHTMLParser* = ref object of RootObj
  parser*: HTMLParser
  ipcClient*: IPCClient

proc parse*(sandboxedHtmlParser: SandboxedHTMLParser, input: string) =
  sandboxedHtmlParser.ipcClient.send({"status": IPC_CLIENT_RESULT, "payload": {}.toTable}.toTable)
