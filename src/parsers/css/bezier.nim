#[
  Parametric bezier curves.

  This is based on `servo/components/style/bezier.rs` in Servo.
]#
import csstypes

const NEWTON_METHOD_ITERATIONS: int = 8

type Bezier* = ref object of RootObj
  ax*: float
  bx*: float
  cx*: float
  ay*: float
  by*: float
  cy*: float

proc sampleCurveX*(bezier: Bezier, t: float): float {.inline.} =
  ((bezier.ax * t + bezier.bx) * t + bezier.cx) * t

proc sampleCurveY*(bezier: Bezier, t: float): float {.inline.} =
  ((bezier.ay * t + bezier.by) * t + bezier.cy) * t

proc sampleCurveDerivativeX*(bezier: Bezier, t: float): float {.inline.} =
  (3.0 * bezier.ax * t + 2.0 * bezier.bx) * t + bezier.cx

proc solveCurveX*(bezier: Bezier, x: float): float {.inline.} =
  # Fast solver: Newton's Method of Solving a Bezier Curve
  var t = x
  for _ in 0..NEWTON_METHOD_ITERATIONS:
    let x2 = bezier.sampleCurveX(t)
    if x2 ~~ x:
      t
    let dx = bezier.sampleCurveDerivativeX(t)
    if dx ~~ 0.0:
      break
    t -= (x2 - x) / dx

  # Slow solver, last resort: Brute-force/bisection testing
  var
    low = 0.0
    high = 1.0
    t = x

  if t < low:
    low

  if t > high:
    high

  while low < high:
    let x2 = bezier.sampleCurveX(t)
    if x2 ~~ x:
      t
    if x > x2:
      low = t
    else:
      high = t

    t = (high - low) / 2.0 + low

  t

proc solve*(bezier: Bezier, x: float): float {.inline.} =
  bezier.sampleCurveY(bezier.solveCurveX(x))

proc newBezier*(x1: CSSFloat, y1: CSSFloat, x2: CSSFloat, y2: CSSFloat): Bezier =
  let 
    cx = 3 * x1
    bx = 3 * (x2 - x1) - cx
    cy = 3 * y1
    by = 3 * (y2 - y1) - cy

  Bezier(
    ax: 1.0 - cx - bx,
    bx: bx,
    cx: cx,
    ay: 1.0 - cy - by,
    by: by,
    cy: cy
  )
