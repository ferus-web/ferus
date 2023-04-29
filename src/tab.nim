#[
  Each tab has it's own DOM and JS runtime.

  This code is licensed under the MIT license
]#
import parsers/dom

type Tab* = ref object of RootObj
  dom*: DOM
