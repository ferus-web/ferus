import std/[logging, options]
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
  ## Used to mark branches of a function as "unreachable".
  ## They'll cause a crash upon being executed.
  assert false, "Unreachable"

template failCond*(cond: untyped) =
  ## Immediately halts execution of a function if the provided condition is `false`.
  ## This does not get elided in release builds.
  let res = cond

  if not res:
    error "Condition failed! Halting execution of function: `" & astToStr(cond) & '`'
    return
