#[
  Smart types for CSS/HTML values

  Basic butterfly syntax (inside Butterfly.payload) is:
  ```
  type[value in quotations]
  ```

  where `type` can be:
  b - bool
  s - string
  c - char
  i - int
  f - float
]#
import tables, chronicles, strutils

#[
  Convert some data into a boolean.

  For eg.,
  <html idonthaveanideaastoatagthatusesaboolean=true></html>

  Representation in butterfly form will be: ""true""
]#


proc ferusButterflyBool*(data: string): bool =
  if data == "true":
    return true
  elif data == "false":
    return false
  elif data == "yes":
    return true
  elif data == "no":
    return false

  error "[src/butterfly.nim] ferusButterflyBool() hit an error -- payload does not match any(true, false, yes, no)"

# This doesn't even need to exist
proc ferusButterflyChar*(data: string): char =
  if data.len < 1:
    error "[src/butterfly.nim] ferusButterflyChar() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"
    return ' '
  data[0]

proc ferusButterflyInt*(data: string): int =
  if data.len < 1:
    error "[src/butterfly.nim] ferusButterflyInt() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"

  parseInt(data)

proc ferusButterflyFloat*(data: string): float =
  if data.len < 1:
    error "[src/butterfly.nim] ferusButterflyFloat() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"
  parseFloat(data)

type
  ButterflyType* = enum
    btInt,
    btStr,
    btBool,
    btChar,
    btFloat,
    btNone

  ButterflyQuality* = enum
    bqGood,        # Perfectly okay butterfly payload
    bqEmpty,       # Empty butterfly payload
    bqMalformed,   # Slightly erroneous payload, Ferus will try to evaluate what it means, this may cause wonkiness. If no good evaluation is done, the quality will degrade to bqBad.
    bqBad          # Bad payload. Ferus won't even attempt to decipher what you mean.

  Butterfly* = ref object of RootObj
    butterType*: ButterflyType
    payload*: string
    quality*: ButterflyQuality

proc processInt*(butterfly: Butterfly): int =
  if butterfly.butterType != ButterflyType.btInt:
    error "[src/butterfly.nim] Attempt to process int out of a non-int butterfly"
    return 0

  return ferusButterflyInt(butterfly.payload)

proc processBool*(butterfly: Butterfly): bool =
  if butterfly.butterType != ButterflyType.btBool:
    error "[src/butterfly.nim] Attempt to process bool out of a non-bool butterfly"
    return true

  return ferusButterflyBool(butterfly.payload)

proc processChar*(butterfly: Butterfly): char =
  if butterfly.butterType != ButterflyType.btChar:
    error "[src/butterfly.nim] Attempt to process char out of a non-char butterfly"
    return ' '

  return ferusButterflyChar(butterfly.payload)

proc processFloat*(butterfly: Butterfly): float =
  if butterfly.butterType != ButterflyType.btFloat:
    error "[src/butterfly.nim] Attempt to process float out of a non-float butterfly"
    return 0.0

  return ferusButterflyFloat(butterfly.payload)

#[
  Get a pretty, new, shiny butterfly delivered to your house.
  Warning: It may and WILL fly away as soon as you open the jar!
]#
proc newButterfly*(data: string): Butterfly =
  if data.len < 1:
    error "[src/butterfly.nim] Sanity check failed; raw data can not be empty!"

  var
    payload = ""
    bType: ButterflyType
    pIdx = -1

  for c in data:
    inc pIdx
    if c == '[' or c == ']':
      continue

    if pIdx == 0:
      continue
    payload = payload & c

  if data[0] == 'i':
    bType = ButterflyType.btInt
  elif data[0] == 's':
    bType = ButterflyType.btStr
  elif data[0] == 'c':
    bType = ButterflyType.btChar
  elif data[0] == 'b':
    bType = ButterflyType.btBool
  elif data[0] == 'f':
    bType = ButterflyType.btFloat
  else:
    error "[src/butterfly.nim] Invalid payload! Terminating!"

  Butterfly(payload: payload, butterType: bType, quality: ButterflyQuality.bqGood)

var x = newButterfly("f[4.4]")
echo $x.processFloat()