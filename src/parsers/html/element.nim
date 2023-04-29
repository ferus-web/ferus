#[
  A HTML element.

  This code is licensed under the MIT license
]#

# Not used yet.
type ElementType* = enum
  Element, 
  Text,
  Comment

type HTMLElement* = ref object of RootObj
  tagName*: string
  children*: seq[HTMLElement]
  parentElement*: HTMLElement
  textContent*: string

proc findByTagName*(htmlElem: HTMLElement, name: string): HTMLElement =
  for child in htmlElem.children:
    if child.tagName == name:
      return child
  
  raise newException(ValueError, "")

proc newHTMLElement*(tagName: string, textContent: string, root: HTMLElement): HTMLElement =
  HTMLElement(tagName: tagName, children: @[], 
              parentElement: root, textContent: textContent)
