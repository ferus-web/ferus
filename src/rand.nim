#[
  Pseudo-random number generation for Ferus.
  This provides two generators, one is the non-cryptographically secure but extremely fast and efficient Xoroshiro128+, and the other is the cryptographically secure but slower generator (/dev/urandom on UNIX-like systems)

  This code is licensed under the MIT license
]#

import chronicles
import std/[random, sysrand]

# Small character set for the hasher
var CHAR_SET = [
  'a', 'A',
  'b', 'B',
  'c', 'C',
  'd', 'D',
  'e', 'E',
  'f', 'F',
  'g', 'G',
  'h', 'H',
  'i', 'I',
  'j', 'J',
  'k', 'K',
  'l', 'L',
  'm', 'M',
  'n', 'N',
  'o', 'O',
  'p', 'P',
  'q', 'Q',
  'r', 'R',
  's', 'S', 
  't', 'T',
  'u', 'U',
  'v', 'V',
  'w', 'W',
  'x', 'X',
  'y', 'Y',
  'z', 'Z',
  # '@', '!', '?', '#', '$', '%', '^', '&', '*', '(', ')', '{', '}', '|', '/', ':', 
  # ';', '[', ']', ',', '.', '<', '>', '~', '`', '\'',
  '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
]

info "[src/rand.nim] Randomizing Xoroshiro128+ initial state"
randomize()

proc getRandAlphabetSequence*(stop: int): string {.inline.} =
  var x = ""
  for i in 0..stop:
    shuffle(CHAR_SET)
    x = x & CHAR_SET[0]

  x

proc randint*(start: int, stop: int): int {.inline.} =
  rand(start..stop)

proc randints*(numIterations: int, start: int, stop: int): seq[int] {.inline.} =
  var
    x: seq[int] = @[]

  for y in 0..numIterations:
    x.add(randint(start, stop))

  x

proc choice*[T](sequence: var openArray[T]): T {.inline.} =
  sample(sequence)

proc shuffleSeq*[T](sequence: var openArray[T]) {.inline.} =
  shuffle(sequence)

when not defined(ferusNoSecureRng):
  proc secureRand*(numBytes: int): seq[byte] {.inline.} =
    urandom(numBytes)
