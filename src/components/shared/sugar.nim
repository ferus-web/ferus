import std/options
import results

proc `*`*[T](opt: Option[T]): bool {.inline.} =
  opt.isSome

proc `!`*[T](opt: Option[T]): bool {.inline.} =
  opt.isNone

proc `&`*[T](opt: Option[T]): T {.inline.} =
  opt.get()

proc `!`*[T, E](res: Result[T, E]): bool {.inline.} =
  res.isErr

proc `*`*[T, E](res: Result[T, E]): bool {.inline.} =
  res.isOk

proc `&`*[T, E](res: Result[T, E]): T {.inline.} =
  res.get()

proc `@`*[T, E](res: Result[T, E]): E {.inline.} =
  res.error()

template unreachable*() =
  assert false, "Unreachable"
