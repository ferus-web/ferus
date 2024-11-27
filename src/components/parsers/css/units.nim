import pkg/[jsony]

const UnitsList = staticRead("static/units.json")
const Units*: seq[string] = fromJson(UnitsList, seq[string])
