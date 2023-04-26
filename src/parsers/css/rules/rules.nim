import ../../../butterfly
import tables

const FERUS_CSS_TYPES = {
  "color": "r",
  "size": "f"
}.toTable

proc getCssTypes*(attr: string): string =
  FERUS_CSS_TYPES[attr]
