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
import tables, chronicles, strutils, panic

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
  
  error "ferusButterflyBool() hit an error -- payload does not match any(true, false, yes, no)"

#[
  Convert some data into a char.
  I have no clue why this exists.
]#
proc ferusButterflyChar*(data: string): char =
  if data.len < 1:
    error "ferusButterflyChar() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"
    return ' '
  data[0]

#[
  Convert some data into an int.

  For eg.

  p1 {
    x: 4;
  }

  where p1[x] = 4
]#
proc ferusButterflyInt*(data: string): int =
  if data.len < 1:
    error "ferusButterflyInt() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"

  parseInt(data)

#[
  Convert some data into rgba form.

  For eg.

  p1 {
    color: rgba(4.4, 3.2, 5.5, 0.9);
  }

  where p1[color] = [r: 4.4, g: 3.2, b: 5.5, a: 0.9]
]#
proc ferusButterflyRgba*(data: string): tuple[r: float, g: float, b: float, a: float] =
  if data.len < 1:
    error "ferusButterflyRgba() hit an error -- payload is non-existant"

  echo data

#[
  Convert some data into float form.

  For eg.

  p1 {
    x: 4.4;
  }

  where p1[x] = 4.4
]#
proc ferusButterflyFloat*(data: string): float =
  if data.len < 1:
    error "ferusButterflyFloat() hit an error -- payload is non-existant!!!! (len < 1; sanity check failed)"
  parseFloat(data)


type
  #[
    The type determined to be valid for a butterfly.

    btInt - integer
    btStr - string
    btBool - boolean
    btChar - character
    btFloat - floating-point number
    btRgba - red-green-blue-alpha tuple
    btNone - ???
  ]#
  ButterflyType* = enum
    btInt,
    btStr,
    btBool,
    btChar,
    btFloat,
    btRgba,
    btNone
  
  #[
    The "quality" of the butterfly, or how quirky it is.

    This isn't used anywhere yet. This will be used to balance out quirks later.
  ]#
  ButterflyQuality* = enum
    bqGood,        # Perfectly okay butterfly payload
    bqEmpty,       # Empty butterfly payload
    bqMalformed,   # Slightly erroneous payload, Ferus will try to evaluate what it means, this may cause wonkiness. If no good evaluation is done, the quality will degrade to bqBad.
    bqBad          # Bad payload. Ferus won't even attempt to decipher what you mean.

  #[
    The Butterfly object. This is used to determine the type of an object by representing it in an intermediate representation form.
  ]#
  Butterfly* = ref object of RootObj
    butterType*: ButterflyType
    payload*: string
    quality*: ButterflyQuality

#[
  Process an int out of a butterfly
]#
proc processInt*(butterfly: Butterfly): int =
  if butterfly.butterType != ButterflyType.btInt:
    error "Attempt to process int out of a non-int butterfly"
    return 0

  return ferusButterflyInt(butterfly.payload)

#[
  Process a boolean out of a butterfly
]#
proc processBool*(butterfly: Butterfly): bool =
  if butterfly.butterType != ButterflyType.btBool:
    error "[src/butterfly.nim] Attempt to process bool out of a non-bool butterfly"
    return true

  return ferusButterflyBool(butterfly.payload)

#[
  Process a character out of a butterfly
]#
proc processChar*(butterfly: Butterfly): char =
  if butterfly.butterType != ButterflyType.btChar:
    error "[src/butterfly.nim] Attempt to process char out of a non-char butterfly"
    return ' '

  return ferusButterflyChar(butterfly.payload)

#[
  Process a float out of a butterfly
]#
proc processFloat*(butterfly: Butterfly): float =
  if butterfly.butterType != ButterflyType.btFloat:
    error "[src/butterfly.nim] Attempt to process float out of a non-float butterfly"
    return 0.0

  return ferusButterflyFloat(butterfly.payload)

#[
  Instantiate a new Butterfly object.
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
  elif data[0] == 'r':
    bType = ButterflyType.btRgba
  else:
    error "[src/butterfly.nim] Invalid payload! Terminating!"

  Butterfly(payload: payload, butterType: bType, quality: ButterflyQuality.bqGood)
