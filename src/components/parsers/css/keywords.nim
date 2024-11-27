import pkg/[jsony]

const KeywordsList = staticRead("static/keywords.json")
const Keywords*: seq[string] = fromJson(KeywordsList, seq[string])
