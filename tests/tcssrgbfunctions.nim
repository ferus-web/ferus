import std/[logging]
import components/style/functions
import components/parsers/css/types
import colored_logger, pretty

addHandler(newColoredLogger())

var val = function("rgba", @[number 255, number 230, number 80, number 32])

print val

let converted = evaluateRGBFunction(val)
print converted
