type CSSFloat* = ref object of RootObj
  val*: float

proc newCSSFloat*(val: float): CSSFloat =
  CSSFloat(val)
