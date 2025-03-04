## Implementation of CSS3 functions like `rgba`, `rgb`, etc.
##
## Author:
## Trayambak Rai (xtrayambak at disroot dot org)
import std/[logging, strutils, options]
import ../parsers/css/[types]
import ../shared/sugar
import pkg/[chroma]

proc evaluateRGBAFunction*(value: CSSValue): Option[ColorRGBA] =
  ## Evaluate a RGBA function (`rgba()`)
  ## https://www.w3.org/TR/css-color-4#rgb-functions
  failCond value.fn.arguments.len == 4 # We need the r, g, b and a components. If not found, return nothing.

  let
    r = value.fn.arguments[0]
    g = value.fn.arguments[1]
    b = value.fn.arguments[2]
    a = value.fn.arguments[3]

  failCond r.kind in { cssInteger, cssFloat }
  failCond g.kind in { cssInteger, cssFloat }
  failCond b.kind in { cssInteger, cssFloat }
  failCond a.kind in { cssInteger, cssFloat }

  let
    red =
      case r.kind
      of cssInteger: r.num.uint8
      of cssFloat: clamp(r.flt * 255, 0, 255).uint8
      else: unreachable; 0

    green =
      case g.kind
      of cssInteger: g.num.uint8
      of cssFloat: clamp(g.flt * 255, 0, 255).uint8
      else: unreachable; 0

    blue =
      case b.kind
      of cssInteger: b.num.uint8
      of cssFloat: clamp(b.flt * 255, 0, 255).uint8
      else: unreachable; 0

    alpha =
      case a.kind
      of cssInteger: a.num.uint8
      of cssFloat: clamp(a.flt * 255, 0, 255).uint8
      else: unreachable; 0
  
  # TODO: Handle percentages!

  return some(rgba(red, green, blue, alpha))

proc evaluateRGBFunction*(value: CSSValue): Option[ColorRGB] =
  ## Evaluate a RGB function (`rgb()`)
  ## https://www.w3.org/TR/css-color-4#rgb-functions
  failCond value.fn.arguments.len == 3 # We need the r, g and b components. If not found, return nothing.

  let
    r = value.fn.arguments[0]
    g = value.fn.arguments[1]
    b = value.fn.arguments[2]

  failCond r.kind in { cssInteger, cssFloat }
  failCond g.kind in { cssInteger, cssFloat }
  failCond b.kind in { cssInteger, cssFloat }

  let
    red =
      case r.kind
      of cssInteger: r.num.uint8
      of cssFloat: clamp(r.flt * 255, 0, 255).uint8
      else: unreachable; 0

    green =
      case g.kind
      of cssInteger: g.num.uint8
      of cssFloat: clamp(g.flt * 255, 0, 255).uint8
      else: unreachable; 0

    blue =
      case b.kind
      of cssInteger: b.num.uint8
      of cssFloat: clamp(b.flt * 255, 0, 255).uint8
      else: unreachable; 0
  
  # TODO: Handle percentages!

  return some(rgb(red, green, blue))

proc evaluateRGBXFunction*(value: CSSValue): Option[ColorRGBA] =
  ## Evaluate a color functional notation in CSS.
  ## This is a "one-size-fits-all" function which handles
  ## `rgba()` and `rgb()` notations.
  assert(value.kind == cssFunction, "evaluateRGBXFunction() called on CSS value which isn't a functional notation")

  # "Like keywords, function names are ASCII case-insensitive" [quoted from https://www.w3.org/TR/css-values-3/#functional-notations]
  let fun = value.fn.name.toLowerAscii()

  case fun
  of "rgba":
    return evaluateRGBAFunction(value)
  of "rgb":
    let color = evaluateRGBFunction(value)

    if !color:
      return

    let rgb = &color

    return some(rgba(rgb.r, rgb.g, rgb.b, 255))
  else:
    unreachable
