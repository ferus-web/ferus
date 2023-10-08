#[
  Mrityu - a simple crash log generator
]#
import std/[os, times, strformat], librng

const 
  NimblePkgVersion {.strdefine.} = "???"
  CRASH_MESSAGES = @[
    "O noes! :(",
    "It was a bit flip, I swear!",
    "Segmentation Fault (Ferus dumped)",
    "The 4chan jannies have pwned you with their 1337 h4x0r skills!",
    "Haha, Ferus go brrrrr!",
    "I saw you watch cringe content, so I closed the browser for your own good. - tray"
  ]

type CrashReason* = enum
  crOutOfMem
  crUnhandledException
  crIOError

proc genMrityu*(rng: RNG, reason: CrashReason): string =
  var genericLog = fmt"""
[FERUS CRASH REPORT]
# {rng.choice(CRASH_MESSAGES, genAlgo=rngLehmer64)}
Ferus Version: {NimblePkgVersion}
Compile Time: {CompileDate} {CompileTime}
Host OS: {hostOS}
Arch: {hostCPU}
Nim Compiler: {NimVersion}
Endianness: {cpuEndian}

"""

  if reason == crOutOfMem:
    genericLog &= fmt"""
[OUT OF MEMORY CRASH]
Memory Managed by GC:   {getTotalMem()}
Occupied Memory:        {getOccupiedMem()}
Free/Unoccupied Memory: {getFreeMem()}
    """
  elif reason == crIOError:
    genericLog &= "[IO ERROR CRASH]"
  elif reason == crUnhandledException:
    genericLog &= fmt"""
[UNHANDLED EXCEPTION]
"""

  genericLog

proc mrityuInit*(reason: CrashReason, writeToStdout: bool = true) =
  # TODO: since this also covers OOM errors, should we be allocating more memory for a crash
  # log? Real confusing stuff.
  let
    rng = newRNG()
    msg = genMrityu(rng, reason)

  if writeToStdout:
    echo msg

  # FIXME: put the crash files in a better place than the home directory
  let file = open(getHomeDir() & "ferus-crash-log-" & $getTime(), fmWrite)
  defer: file.close()

  file.write(msg)

  echo "This log was written to: " & getHomeDir() & "ferus-crash-log-" & $getTime()
