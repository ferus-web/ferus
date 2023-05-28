import chronicles, strformat, times, osproc, taskpools,
       ../../rand,
       ../../ipc/server,
       ../../sandbox/processtypes

# The higher the number, more the time taken to generate the string,
# but lesser the chance for a Broker signature conflict causing major confusions
# TODO: Put an end to Broker conflicts, make sure they never share the same signature.
const FERUS_BROKER_ALPHABET_SEQUENCE_LENGTH = 128
var tp = Taskpool.new(num_threads=128)

type Broker* = ref object of RootObj
  ipcServer*: IPCServer
  signature*: string

proc createNewProcess*(broker: Broker, procType: ProcessType) =
  info "[src/sandbox/linux/broker.nim] Broker is creating new process!"
  let cmd = "./libferuscli" & 
    fmt" --role={processTypeToString(procType)}" & 
    fmt" --unix-time-at-launch={epochTime().int}" &
    fmt" --broker-affinity-signature={broker.signature}" &
    fmt" --ipc-server-port={broker.ipcServer.port}"

  let _ = tp.spawn execCmd(cmd)
  info "[src/sandbox/linux/broker.nim] libferuscli launched!"

proc newBroker*(ipcServer: IPCServer): Broker =
  var hasherInput = getRandAlphabetSequence(FERUS_BROKER_ALPHABET_SEQUENCE_LENGTH)
  info "[src/sandbox/linux/broker.nim] New broker initializing!", hasherInput=hasherInput
  Broker(ipcServer: ipcServer, signature: hasherInput)
