import os
import chronicles

type CoreThreadManager* = ref object of RootObj
  threads*: seq[Thread[int]]

proc threadedExec*[T](fn: proc() {.gcsafe.}) =


threadedExec(threadedExec)
