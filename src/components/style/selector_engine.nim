## Selector matching engine
## Author:
## Trayambak Rai (xtrayambak at disroot dot org)
import std/[logging]
import ../parsers/html/[document]
import ../parsers/css/[types]

proc matches*(selector: Selector, element: HTMLElement): bool =
  case selector.kind
  of skType:
    return $element.tag == selector.tag
  of skClass:
    return element.classes.contains(selector.class)
  else:
    warn "unimplemented: selector matching logic for: " & $selector.kind
    return false
