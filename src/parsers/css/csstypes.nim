import math

type CSSFloat* = float

#[
  Determine if two CSSFloat(s) are nearly identical, only off by a few decimal places.
  approxEqual() and the template below it have the same job, just for different programming practices.

  approxEqual():
  ```
  var
    x = CSSFloat(3.884524562)
    y = CSSFloat(3.884524566)

  assert(x.approxEqual(y))
  ```
  is the same as:
  ```
  var
    x = CSSFloat(3.884524562)
    y = CSSFloat(3.884524566)

  assert(x ~~ y)
  ```
]#
proc approxEqual*(cssf1, cssf2: CSSFloat): bool =
  almostEqual(cssf1, cssf2)

template `~~`* (a, b: CSSFloat): bool =
  almostEqual(a, b)
