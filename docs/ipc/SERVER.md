# Guide to writing code for the IPC server (master process)
This guide will tell you how to write code that targets the master component.
<small>Author(s): Trayambak Rai (xTrayambak)</small>
<small>Last Edited: November 2, 2024</small>
<small>Based Off: Ferus 0.2.2</small>

# Receiving Messages
The message handler is defined in [the master component code](../../src/components/master/master.nim). You can add IPC magic opcode handlers as you please here, granted that they are defined in the `FerusMagic` enum in the `ferus_ipc` package.

# Security Practices
Treat all data coming from a client with suspicion. We can never be certain if a client has been compromised. \
When running logic for a magic opcode, make sure to execute all required sanity checks. \
If any of the checks fail, [report it as a bad message](#reporting-bad-messages).

Valid checks are:
- If a process requests access to a file, check whether it really needs it. For instance,
  - A network process has no business randomly checking the user's documents directory
  - A renderer should never be trying to override the browser's security policies
  - A HTML parser shouldn't be trying to recursively delete the entire file system
- If a process initiates a data transfer, check whether it really needs it. For instance,
  - Currently, only a renderer needs to initiate data transfers for fetching images that it encounters in a provided document.

# Reporting Bad Messages
You can use the `reportBadMessage` procedure to report a bad message from a process. Here is the function signature:
```nim
proc reportBadMessage*(
  server: var IPCServer, 
  process: FerusProcess,
  message: string,
  severity: BadMessageSeverity)
```

You must pass the IPC server, the process that sent the bad message, a message explaining why the message doesn't make sense, and a severity enum that can be `Low`, `Medium` or `High`.

## Rating Bad Message Severity
`Low` severity is to be used for an error that probably happened due to the user/web programmer entering faulty data. Say, the JavaScript process sending a URL that is malformed. These messages will simply be ignored by the server. \
`Medium` severity is to be used when a process might be being confused into executing bad instructions. Say, the JavaScript process has an improperly configured function that requests invalid data from the server. The process in this case will be disconnected from the server. \
`High` severity is to be used when a process has most likely been fully taken over by a bad actor and is out of control, trying to access things that it never should have access to and executing opcodes that it doesn't have the permission/scope to use. In this case, the process will be disconnected from the server and the server will attempt to run `kill(2)` on the process' PID.

# Sending Messages
You can use the `send` procedure to send a message to a process from the server. The signature is as follows:
```nim
proc send*[T](
  server: var IPCServer,
  sock: Socket,
  data: T
)
```
Where `T` is any struct or type that is serializable to JSON. Unserializable structs need to be wrapped up (see how the [Renderer component wraps up](../../src/components/renderer/ipc.nim) ferusgfx's `DisplayList` structs)

# Receiving Messages
You can use the `receive` procedure to receive a message from a process, but this isn't recommended as it is a blocking procedure.

There are two `receive` procedures. One returns a raw string, which is likely a stream of JSON.
```nim
proc receive*(
  server: IPCServer,
  socket: Socket
): string
```

The second `receive` procedure automatically attempts to turn this likely-stream-of-JSON into a struct that you provide. If it can't do that,
then it will return an empty `Option[T]`. If it can, it will return the data by putting it inside the `Option[T]`.
```nim
proc receive*[T](
  server: IPCServer,
  socket: Socket,
  kind: typedesc[T]
): Option[T]
```

The better way to receive messages is to use a "send-if-you-want" model. This model is guaranteed to not block, as it uses the `handler` procedure inside the server
and the server polls the file descriptor of every process' socket to see if it has sent something. If it has, then that data will be passed on to the `handler` procedure. \
This code is [over here](../../src/components/master/master.nim#L402)

# Data Transfers
Data transfers are a mechanism used by the IPC layer to transfer data between two child processes without them having to directly establish a connection to each other. \
Each data transfer is mediated by the master process, and as such, it can apply certain rules and regulations to a transfer to ensure that unnecessary data is not
transmitted across processes. The data transfer handler is defined in the [`dataTransfer` function](../../src/components/master/master.nim#335)
