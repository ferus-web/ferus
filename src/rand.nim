#[
  Pseudo-random number generation for Ferus.
  This provides two generators, one is the non-cryptographically secure but extremely fast and efficient Xoroshiro128+, and the other is the cryptographically secure but slower generator (/dev/urandom on UNIX-like systems)

  This code is licensed under the MIT license
]#

import chronicles
import std/[random, sysrand]

info "[src/rand.nim] Randomizing Xoroshiro128+ initial state"
randomize()

proc randint*(start: int, stop: int): int =
  rand(start..stop)

proc randints*(numIterations: int, start: int, stop: int): seq[int] =
  var
    x: seq[int] = @[]

  for y in 0..numIterations:
    x.add(randint(start, stop))

  x

proc choice*[T](sequence: var openArray[T]): T =
  sample(sequence)

proc shuffleSeq*[T](sequence: var openArray[T]) =
  shuffle(sequence)

when not defined(ferusNoSecureRng):
  proc secureRand*(numBytes: int): seq[byte] =
    urandom(numBytes)
