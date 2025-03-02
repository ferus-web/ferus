## Yoga bindings
## 
## Yoga is licensed under the MIT license.
## Copyright (c) Meta Platforms, Inc. and affiliates.
##
## These bindings, however, are licensed under the GNU General Public License, version 3.
## Author: Trayambak Rai (xtrayambak at disroot dot org)
import std/[strutils]

static:
  let pwd = gorge("pwd")
  discard gorge("mkdir ../third_party/yoga/build")
  echo gorge("cd ../third_party/yoga/build && cmake .. -DCMAKE_INSTALL_PREFIX=" & pwd & "/install")
  echo gorge("cd ../third_party/yoga/build && make -j$(nproc)")
  echo gorge("cd ../third_party/yoga/build && make install")
  echo pwd

{.passC: "-I" & gorge("pwd") & "/install/include".}
{.passL: "-L" & gorge("pwd") & "/install/lib64 -lyogacore".}

{.push header: "<yoga/Yoga.h>".}
type
  YGAlign* {.importc, size: sizeof(cint).} = enum
    YGAlignAuto
    YGAlignFlexStart
    YGAlignCenter
    YGAlignFlexEnd
    YGAlignStretch
    YGAlignBaseline
    YGAlignSpaceBetween
    YGAlignSpaceAround
    YGAlignSpaceEvenly

  YGDirection* {.importc, size: sizeof(cint).} = enum
    YGDirectionInherit
    YGDirectionLTR
    YGDirectionRTL

  YGEdge* {.importc, size: sizeof(cint).} = enum
    YGEdgeLeft
    YGEdgeTop
    YGEdgeRight
    YGEdgeBottom
    YGEdgeStart
    YGEdgeEnd
    YGEdgeHorizontal
    YGEdgeVertical
    YGEdgeAll

  YGJustify* {.importc, size: sizeof(cint).} = enum
    YGJustifyFlexStart
    YGJustifyCenter
    YGJustifyFlexEnd
    YGJustifySpaceBetween
    YGJustifySpaceAround
    YGJustifySpaceEvenly

  YGFlexDirection* {.importc, size: sizeof(cint).} = enum
    YGFlexDirectionColumn
    YGFlexDirectionColumnReverse
    YGFlexDirectionRow
    YGFlexDirectionRowReverse

  YGSize* {.bycopy, importc.} = object
    width*, height*: float

  YGNode* {.importc.} = object
  YGNodeRef* {.importc.} = pointer

proc newYGNode*: YGNodeRef {.importc: "YGNodeNew".}
proc clone*(node: var YGNode) {.importc: "YGNodeClone".}
proc free*(node: YGNodeRef) {.importc: "YGNodeFree".}
proc freeRecursive*(node: YGNodeRef) {.importc: "YGNodeFreeRecursive".}
proc finalize*(node: YGNodeRef) {.importc: "YGNodeFinalize".}
proc reset*(node: YGNodeRef) {.importc: "YGNodeReset".}
proc calculateLayout*(node: YGNodeRef, availableWidth, availableHeight: float, ownerDirection: YGDirection) {.importc: "YGNodeCalculateLayout".}
func hasNewLayout*(node: var YGNode): bool {.importc: "YGNodeGetHasNewLayout".}
proc `hasNewLayout=`*(node: YGNodeRef, hasNewLayout: bool) {.importc: "YGNodeSetHasNewLayout".}
func isDirty*(node: var YGNode): bool {.importc: "YGNodeIsDirty".}
proc markDirty*(node: YGNodeRef): bool {.importc: "YGNodeMarkDirty".}
proc insertChild*(node: YGNodeRef, child: YGNodeRef, index: uint64) {.importc: "YGNodeInsertChild".}
proc swapChild*(node: YGNodeRef, child: YGNodeRef, index: uint64) {.importc: "YGNodeInsertChild".}
proc removeChild*(node: YGNodeRef, child: YGNodeRef) {.importc: "YGNodeRemoveChild".}
proc removeAllChildren*(node: YGNodeRef) {.importc: "YGNodeRemoveAllChildren".}
proc setChildrenInternal(owner: YGNodeRef, children: ptr UncheckedArray[YGNodeRef], count: uint64) {.importc: "YGNodeSetChildren".}
proc getChild*(node: YGNodeRef, index: uint64): YGNodeRef {.importc: "YGNodeGetChild".}
proc childCount*(node: var YGNode): uint64 {.importc: "YGNodeGetChildCount".}
proc getOwner*(node: YGNodeRef): YGNodeRef {.importc: "YGNodeGetOwner".}
proc getParent*(node: YGNodeRef): YGNodeRef {.importc: "YGNodeGetParent".}

proc getLeft*(node: var YGNode): float {.importc: "YGNodeLayoutGetLeft".}
proc getTop*(node: var YGNode): float {.importc: "YGNodeLayoutGetTop".}
proc getRight*(node: var YGNode): float {.importc: "YGNodeLayoutGetRight".}
proc getBottom*(node: var YGNode): float {.importc: "YGNodeLayoutGetBottom".}
proc getWidth*(node: var YGNode): float {.importc: "YGNodeLayoutGetWidth".}
proc getHeight*(node: var YGNode): float {.importc: "YGNodeLayoutGetHeight".}
proc getDirection*(node: var YGNode): YGDirection {.importc: "YGNodeLayoutGetDirection".}
proc getHadOverflow*(node: var YGNode): bool {.importc: "YGNodeLayoutGetHadOverflow".}
proc getMargin*(node: var YGNode, edge: YGEdge): float {.importc: "YGNodeLayoutGetMargin".}
proc getBorder*(node: var YGNode, edge: YGEdge): float {.importc: "YGNodeLayoutGetBorder".}
proc getPadding*(node: var YGNode, edge: YGEdge): float {.importc: "YGNodeLayoutGetPadding".}

proc copyStyle*(dest: YGNodeRef, srcNode: var YGNode) {.importc: "YGNodeCopyStyle".}
proc setDirection*(node: YGNodeRef, direction: YGDirection) {.importc: "YGNodeStyleSetDirection".}
proc setFlexDirection*(node: YGNodeRef, flexDirection: YGFlexDirection) {.importc: "YGNodeStyleSetFlexDirection".}
proc getFlexDirection*(node: var YGNode): YGFlexDirection {.importc: "YGNodeStyleGetFlexDirection".}
proc setJustifyContent*(node: YGNodeRef, justifyContent: YGJustify) {.importc: "YGNodeStyleSetJustifyContent".}
proc getJustifyContent*(node: var YGNode): YGJustify {.importc: "YGNodeStyleGetJustifyContent".}
proc setWidth*(node: YGNodeRef, width: float) {.importc: "YGNodeStyleSetWidth".}
proc setWidthPercent*(node: YGNodeRef, width: float) {.importc: "YGNodeStyleSetWidthPercent".}
proc setWidthAuto*(node: YGNodeRef) {.importc: "YGNodeStyleSetWidthAuto".}
proc setWidthMaxContent*(node: YGNodeRef) {.importc: "YGNodeStyleSetWidthMaxContent".}
proc setWidthFitContent*(node: YGNodeRef) {.importc: "YGNodeStyleSetWidthFitContent".}
proc setWidthStretch*(node: YGNodeRef) {.importc: "YGNodeStyleSetWidthStretch".}

proc setHeight*(node: YGNodeRef, height: float) {.importc: "YGNodeStyleSetHeight".}
proc setHeightPercent*(node: YGNodeRef, height: float) {.importc: "YGNodeStyleSetHeightPercent".}
proc setHeightAuto*(node: YGNodeRef) {.importc: "YGNodeStyleSetHeightAuto".}
proc setHeightMaxContent*(node: YGNodeRef) {.importc: "YGNodeStyleSetHeightMaxContent".}
proc setHeightFitContent*(node: YGNodeRef) {.importc: "YGNodeStyleSetHeightFitContent".}
proc setHeightStretch*(node: YGNodeRef) {.importc: "YGNodeStyleSetHeightStretch".}

proc setAlignSelf*(node: YGNodeRef, align: YGAlign) {.importc: "YGNodeStyleSetAlignSelf".}

{.pop.}

# Wrapping code, just for convenience.
proc setChildren*(owner: YGNodeRef, children: seq[YGNodeRef]) =
  var arr = cast[ptr UncheckedArray[YGNodeRef]](alloc(children.len * sizeof(YGNodeRef)))
  for i, _ in children:
    arr[i] = children[i]

  setChildrenInternal(owner, arr, children.len.uint64)
  dealloc(arr)
