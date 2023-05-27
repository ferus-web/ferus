#[
  Base class for all boxes
  Ported from https://github.com/CobaltBSD/neosurf/blob/main/src/content/handlers/html/box.h

  This code is licensed under the MIT license
]#
import ../../../parsers/css/csstypes,
       ../../../dom/dom,
       ferushtml, urlly

type
  BoxType* = enum
    btBlock, btInlineContainer,
    btInline, btTable,
    btTableRow, btTableCell,
    btTableRowGroup, btFloatLeft,
    btFloatRight, btInlineBlock,
    btBr, btText, btInlineEnd, 
    btNone, btFlex, btInlineFlex

  BoxFlags* = enum
    bfNewline, bfStyleOwned,
    bfPrinted, bfPrestrip,
    bfClone, bfMeasured,
    bfHasHeight, bfMakeHeight,
    bfNeedMin, bfReplaceDim,
    bfIframe, bfConvertChildren,
    bfIsReplaced

  BoxSide* = enum
    bsTop, bsRight, bsLeft, bsBottom

  BoxBorder* = ref object of RootObj
    color*: CSSColor
    width*: uint

  ColumnType* = enum
    ctWidthUnknown,
    ctWidthFixed,
    ctWidthAuto,
    ctWidthPercent,
    ctWidthRelative

  Column* = ref object of RootObj
    colType*: ColumnType
    width*: int
    min*: int
    max*: int
    positioned*: bool

  ObjectParam* = ref object of RootObj
    name*: string
    value*: Butterfly
    objType*: string
    objParam*: ObjectParam

  ObjectParams* = ref object of RootObj
    data*: URL
    params*: ObjectParam

  Box* = ref object of RootObj
    boxType*: BoxType
    boxFlags*: BoxFlags
    dom*: DOM
    next*: Box
    prev*: Box

    id*: string

    firstChild*: Box
    lastChild*: Box
    parent*: Box

    inlineEnd*: Box
    floatChildren*: Box
    nextFloat*: Box
    floatContainer*: Box
    clearLevel*: int

    pos*: tuple[x, y: int]
    dimensions*: tuple[width, height: int]
    descendants*: tuple[x0, y0, x1, y1: int]

    margin*: seq[int]
    padding*: seq[int]

    boxBorder*: seq[BoxBorder]

    width*: tuple[max, min: int]
    text*: string

    space*: int

    columns*: uint
    rows*: uint

    startColumn*: uint
    column*: Column

    listValue*: int
    listMarker*: Box
    objParams*: ObjectParams

proc newBoxBorder*(color: CSSColor, width: int): BoxBorder =
  BoxBorder(color: color, width: width)

proc newColumn*(colType: ColumnType, width, min, max: int, positioned: bool): Column =
  Column(colType: colType, width: width, min: min, max: max, positioned: positioned)

proc newObjectParam*(name: string, value: Butterfly, objType: string, 
                     objParam: ObjectParam): ObjectParam =
  ObjectParam(name: name, value: value, objType: objType, objParam: objParam)

proc newObjectParams*(data: URL = nil, params: ObjectParam): ObjectParams =
  ObjectParams(data: data, params: params)

proc newBox*(boxType: BoxType, boxFlags: BoxFlags, dom: DOM, id: string, 
             next, prev, firstChild, lastChild, parent, 
             inlineEnd, floatChildren, nextFloat, floatContainer: Box, clearLevel: int, 
             pos: tuple[x, y: int], dimensions: tuple[width, height: int], 
             descendants: tuple[x0, y0, x1, y1: int], margin: seq[int], padding: seq[int], 
             boxBorder: BoxBorder, width: tuple[min, max: int], text: string, space: int, 
             columns: uint, rows: uint, startColumn: uint, column: Column, listValue: int, 
             listMarker: Box, objectParams: ObjectParams): Box =
  Box(boxType: boxType, boxFlags: boxFlags, dom: dom, id: id, next: next, 
      prev: prev, firstChild: firstChild, lastChild: lastChild, parent: parent, 
      inlineEnd: inlineEnd, floatChildren: floatChildren, nextFloat: nextFloat, 
      floatContainer: floatContainer, clearLevel: clearLevel, pos: pos, 
      dimensions: dimensions, descendants: descendants, descendants: descendants, 
      margin: margin, padding: padding, boxBorder: boxBorder, width: width, text: text, 
      space: space, columns: columns, rows: rows, startColumn, column: column, 
      listValue: listValue, listMarker: listMarker, objectParams: objectParams)
