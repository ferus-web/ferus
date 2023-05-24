import ferushtml, ../dom/dom, chronicles


type Tab* = ref object of RootObj
  htmlParser*: HTMLParser
