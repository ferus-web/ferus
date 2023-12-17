import chronicles, strformat, times, osproc, taskpools,
       ../../rand,
       ../../ipc/server,
       ../../sandbox/processtypes,
       firejail,
       policyman

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
    fmt" --ipc-server-port={broker.ipcServer.port}" &
    fmt" --is-worker=true"
  let jail = policymanCreateAppropriateJail(procType)

  when not defined(release):
    discard tp.spawn execCmd(cmd)
  else:
    discard tp.spawn jail.exec(cmd)

  info "[src/sandbox/linux/broker.nim] libferuscli launched!"

proc spawnNewWorker*(broker: Broker, affinitySignature: string, procType: ProcessType) =
  info "[src/sandbox/linux/broker.nim] Broker is spawning new worker/temporary process!"
  let cmd = "./libferuscli" &
    fmt" --role={processTypeToString(ptNetwork)}" &
    fmt" --unix-time-at-launch={epochTime().int}" &
    fmt" --broker-affinity-signature={affinitySignature}" &
    fmt" --ipc-server-port={broker.ipcServer.port}" &
    fmt" --is-worker=true"

  let jail = policymanCreateAppropriateJail(procType)

  when not defined(release):
    discard tp.spawn execCmd(cmd)
  else:
    discard tp.spawn jail.exec(cmd)

proc genSignature*(broker: Broker): string =
  result = getRandAlphabetSequence(FERUS_BROKER_ALPHABET_SEQUENCE_LENGTH)

  while result == broker.signature:
    result = getRandAlphabetSequence(FERUS_BROKER_ALPHABET_SEQUENCE_LENGTH)

proc newBroker*(ipcServer: IPCServer): Broker =
  let hasherInput = getRandAlphabetSequence(FERUS_BROKER_ALPHABET_SEQUENCE_LENGTH)
  info "[src/sandbox/linux/broker.nim] New broker initializing!", hasherInput=hasherInput
  Broker(ipcServer: ipcServer, signature: hasherInput)
