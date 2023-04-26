#[
  Graceful crashes (panics) for Ferus
]#
import strformat

const NEXTLINE = "\n"
macro panic* (reason: string) =
  echo fmt"[src/panic.nim] Ferus has panicked!{NEXTLINE}========{NEXTLINE}{reason}{NEXTLINE}========"
  quit 1
