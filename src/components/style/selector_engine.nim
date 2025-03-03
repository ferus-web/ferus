## Selector matching engine
## Author:
## Trayambak Rai (xtrayambak at disroot dot org)
import std/[logging]
import ../parsers/html/[document]
import ../parsers/css/[types]

proc matches*(selector: Selector, element: HTMLElement): bool =
  case selector.kind
  of skType:
    debug "selector_engine: type selector; element tag is: " & $element.tag &
      "; selector targets tag: " & selector.tag
    return $element.tag == selector.tag
  of skClass:
    debug "selector_engine: class selector; element's classes are: " & element.classes &
      "; selector targets class: " & selector.class
    return element.classes.contains(selector.class)
  else:
    warn "selector_engine: unimplemented: selector matching logic for: " & $selector.kind
    return false
