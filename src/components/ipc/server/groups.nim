import std/[options, strutils]
import ../shared

type FerusGroup* = ref object
  id*: uint64
  processes*: seq[FerusProcess]

proc findProcess*(
    group: FerusGroup,
    kind: FerusProcessKind,
    pKind: ParserKind = pkCSS,
    workers: bool = true,
): Option[FerusProcess] {.inline.} =
  for process in group.processes:
    let a = process.worker == workers and process.kind == kind

    if a and kind == Parser:
      if a and process.pKind == pKind:
        return process.some()
    elif a and kind != Parser:
      return process.some()

proc find*(group: FerusGroup, p: FerusProcess): int {.inline.} =
  for i, process in group.processes:
    if process == p:
      return i

  raise newException(ValueError, "Could not find process in group.")

iterator items*(group: FerusGroup): lent FerusProcess {.inline.} =
  for process in group.processes:
    yield process

proc `[]=`*(group: FerusGroup, i: int, new: sink FerusProcess) {.inline.} =
  group.processes[i] = new

proc `[]`*(group: FerusGroup, i: int): FerusProcess {.inline.} =
  group.processes[i]

iterator pairs*(group: FerusGroup): tuple[i: int, process: FerusProcess] {.inline.} =
  for i, process in group.processes:
    yield (i: i, process: process)

proc validate*(group: FerusGroup) {.inline.} =
  for process in group:
    if process.group != group.id:
      raise newException(
        ValueError,
        "Stray process found in IPC group " &
          "(group=%1, stray=%2)" % [$group.id, $process.group],
      )

proc find*(
    group: FerusGroup, fn: proc(process: FerusProcess): bool
): Option[FerusProcess] {.inline.} =
  for `proc` in group:
    if fn(`proc`):
      return some `proc`

proc findAll*(
    group: FerusGroup, fn: proc(process: FerusProcess): bool
): seq[FerusProcess] {.inline.} =
  for `proc` in group:
    if fn(`proc`):
      result &= `proc`
