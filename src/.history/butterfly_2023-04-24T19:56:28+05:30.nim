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
]#
import tables, chronicles

#[
  Convert some data into a boolean.

  For eg., 
  <html idonthaveanideaastoatagthatusesaboolean=true></html>

  Representation in butterfly form will be: ""true""
]#


proc ferusButterflyBool*(data: string): bool =
  if data == "\"true\"":
    return true
  elif data == "\"false\"":
    return false

proc ferusButterflyInt*(data: string): int =
  # Not implemented yet.
  0

type
  ButterflyType* = enum
    btInt,
    btStr,
    btBool,
    btChar,
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

proc getComputedValue*(butterfly: Butterfly) =
  if butterfly.payload.len < 1:
    #error "[src/butterfly.nim] Butterfly payload malformed! (len < 1, sanity check failed)", malformedPayload=butterfly.payload
    butterfly.quality = ButterflyQuality.bqEmpty

  if butterfly.butterType == ButterflyType.btBool:
    discard ferusButterflyBool(butterfly.payload)


#[
  Get a pretty, new, shiny butterfly delivered to your house.
  Warning: It may and WILL fly away as soon as you open the jar!
]#
proc newButterfly*(data: string): Butterfly =
  var
    payload = ""
    bType: ButterflyType
    pIdx = 0

  for c in data:
    if pIdx == 0:
      continue

    inc pIdx
    payload = payload & c

  if data[0] == 'i':
    bType = ButterflyType.btInt
  elif data[0] == 's':
    bType = ButterflyType.btStr
  elif data[0] == 'c':
    bType = ButterflyType.btChar
  elif data[0] == 'b':
    bType = ButterflyType.btBool
  else:
    error "[src/butterfly.nim] Invalid payload! Terminating!"
    quit

  Butterfly(payload: payload, butterType: bType, quality: ButterflyQuality.bqGood)