{.experimental.}

#[
  Parallel quicksort implementation

  Taken from https://github.com/nim-lang/Nim/issues/2704
]#
import threadpool
import sequtils
import times
import random

proc quickSort[T](a: var seq[T], lo, hi: int) =
    if hi <= lo: return
    let pivot = a[(
      (lo+hi)/2
    ).int]
    var (i, j) = (lo, hi)

    while i <= j:
        if a[i] < pivot:
            inc i
        elif a[j] > pivot:
            dec j
        elif i <= j:
            swap a[i], a[j]
            inc i
            dec j

    parallel:
        spawn quickSort(a, lo, j)
        spawn quickSort(a, i, hi)

proc sort*[T](a: var seq[T]) {.inline.} =
  quickSort(a, a.low, a.high)
