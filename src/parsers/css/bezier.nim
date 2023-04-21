#[
  Parametric bezier curves.

  This is based on `servo/components/style/bezier.rs` in Servo.
]#

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

proc solveCurveX*(bezier: Bezier, x: float, epsilon: float): float {.inline.} =
  var t = x
  for _ in 0..NEWTON_METHOD_ITERATIONS:
    let x2 = bezier.sampleCurveX(t)

proc newBezier*(x1: float, y1: float, x2: float, y2: float): Bezier =
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
