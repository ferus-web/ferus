#[
  Base Nim types with extra stuff to them for CSS' needs

  This code is licensed under the MIT license
]#

import math

type 
  CSSFloat* = float
  CSSColor* = ref object of RootObj
    r*: float64
    g*: float64
    b*: float64
    a*: float64

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

proc newCSSColor*(r: float64, g: float64, b: float64, a: float64): CSSColor =
  CSSColor(r: r, g: g, b: b, a: a)
