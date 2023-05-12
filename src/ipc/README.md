# The Ferus IPC layer

This is Ferus' inter-process-communication (IPC) layer that is used by the main
process to communicate with all child processes.

# client.nim

The IPC Client. This is used by all of the child processes. Be it the renderer,
the HTML/CSS parsers or the JS runtime. Small example:
```nim
import ipc/client

var myIClient = newIPCClient()

# after you call this, the client will run and poll itself
# automatically.
myICClient.heartbeat()
```

# server.nim

The IPC Server. This is only to be created once by the main process. Small example:
```nim
import ipc/server

var myIServer = newIPCServer()

# after you call this, the server will run and poll itself
# automatically

myIServer.heartbeat()
```
