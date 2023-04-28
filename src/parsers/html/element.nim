#[
  A HTML element.

  This code is licensed under the MIT license
]#

type HTMLElement* = ref object of RootObj
  tagName*: string
  children*: seq[HTMLElement]
  parentElement*: HTMLElement
  textContent*: string

proc newHTMLElement*(tagName: string, textContent: string, root: HTMLElement): HTMLElement =
  HTMLElement(tagName: tagName, children: @[], parentElement: root, textContent: textContent)
