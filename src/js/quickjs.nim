# JavaScript binding generator. Horrifying, I know. But it works!
# Warning: Function overloading is currently not implemented. Though there is a
# block dielabel:
#   ...
# around each bound function call, so it shouldn't be too difficult to get it
# working. (This would involve generating JS functions in registerType.)
# Now for the pragmas:
# {.jsctor.} for constructors. These need no `this' value, and are bound as
#   regular constructors in JS. They must return a ref object, which will have
#   a JS counterpart too. (Other functions can return ref objects too, which
#   will either use the existing JS counterpart, if exists, or create a new
#   one. In other words: cross-language reference semantics work seamlessly.)
# {.jsfunc.} is used for binding normal functions. Needs a `this' value, as all
#   following pragmas. As mentioned before, overloading doesn't work but OR
#   generics do. Bare objects (returned by value) can't be passed either, for
#   now. Otherwise, most types should work.
# {.jsfget.} and {.jsfset.} for getters/setters. Note the `f'; bare jsget/jsset
#   can only be used on object fields. (I initially wanted to use the same
#   keyword, unfortunately that didn't work out.)
# {.jsgetprop.} for property getters. Called when GetOwnProperty would return
#   nothing. The key should probably be either a string or an integer.
# {.jshasprop.} for overriding has_property. Must return a boolean.

import macros
import options
import sets
import streams
import strformat
import strutils
import tables
import unicode

import io/promise
import utils/opt

import bindings/quickjs

export opt
export options
export tables

export
  JS_NULL, JS_UNDEFINED, JS_FALSE, JS_TRUE, JS_EXCEPTION, JS_UNINITIALIZED

export
  JS_EVAL_TYPE_GLOBAL,
  JS_EVAL_TYPE_MODULE,
  JS_EVAL_TYPE_DIRECT,
  JS_EVAL_TYPE_INDIRECT,
  JS_EVAL_TYPE_MASK,
  JS_EVAL_FLAG_SHEBANG,
  JS_EVAL_FLAG_STRICT,
  JS_EVAL_FLAG_STRIP,
  JS_EVAL_FLAG_COMPILE_ONLY

export JSRuntime, JSContext, JSValue, JSClassID

export
  JS_GetGlobalObject, JS_FreeValue, JS_IsException, JS_GetPropertyStr,
  JS_IsFunction, JS_NewCFunctionData, JS_Call, JS_DupValue

when sizeof(int) < sizeof(int64):
  export quickjs.`==`

type
  JSErrorEnum* = enum
    # QuickJS internal errors
    JS_EVAL_ERROR0 = "EvalError"
    JS_RANGE_ERROR0 = "RangeError"
    JS_REFERENCE_ERROR0 = "ReferenceError"
    JS_SYNTAX_ERROR0 = "SyntaxError"
    JS_TYPE_ERROR0 = "TypeError"
    JS_URI_ERROR0 = "URIError"
    JS_INTERNAL_ERROR0 = "InternalError"
    JS_AGGREGATE_ERROR0 = "AggregateError"
    # Chawan errors
    JS_DOM_EXCEPTION = "DOMException"

  JSSymbolRefs = enum
    ITERATOR = "iterator"
    ASYNC_ITERATOR = "asyncIterator"
    TO_STRING_TAG = "toStringTag"

  JSStrRefs = enum
    DONE = "done"
    VALUE = "value"
    NEXT = "next"

  JSContextOpaque* = ref object
    creg: Table[string, JSClassID]
    typemap: Table[pointer, JSClassID]
    ctors: Table[JSClassID, JSValue]
    parents: Table[JSClassID, JSClassID]
    gclaz: string
    sym_refs: array[JSSymbolRefs, JSAtom]
    str_refs: array[JSStrRefs, JSAtom]
    Array_prototype_values: JSValue
    Object_prototype_valueOf*: JSValue
    err_ctors: array[JSErrorEnum, JSValue]
    dummy_ref_proto: JSValue

  JSRuntimeOpaque* = ref object
    plist: Table[pointer, pointer] # Nim, JS
    flist: seq[seq[JSCFunctionListEntry]]
    fins: Table[JSClassID, proc(val: JSValue)]

  JSFunctionList* = openArray[JSCFunctionListEntry]

  JSError* = ref object of RootObj
    e*: JSErrorEnum
    message*: string

const QuickJSErrors = [
  JS_EVAL_ERROR0,
  JS_RANGE_ERROR0,
  JS_REFERENCE_ERROR0,
  JS_SYNTAX_ERROR0,
  JS_TYPE_ERROR0,
  JS_URI_ERROR0,
  JS_INTERNAL_ERROR0,
  JS_AGGREGATE_ERROR0
]

func getOpaque*(ctx: JSContext): JSContextOpaque =
  return cast[JSContextOpaque](JS_GetContextOpaque(ctx))

func getOpaque*(rt: JSRuntime): JSRuntimeOpaque =
  return cast[JSRuntimeOpaque](JS_GetRuntimeOpaque(rt))

var runtimes {.threadVar.}: seq[JSRuntime]

proc newJSRuntime*(): JSRuntime =
  let rt = JS_NewRuntime()
  let opaque = new(JSRuntimeOpaque)
  GC_ref(opaque)
  JS_SetRuntimeOpaque(rt, cast[pointer](opaque))
  # Must be added after opaque is set, or there is a chance of
  # nim_finalize_for_js dereferencing it (at the new call).
  runtimes.add(rt)
  return rt

proc newJSContext*(rt: JSRuntime): JSContext =
  let ctx = JS_NewContext(rt)
  var opaque = new(JSContextOpaque)
  GC_ref(opaque)

  block: # get well-known symbols and other functions
    let global = JS_GetGlobalObject(ctx)
    block:
      let sym = JS_GetPropertyStr(ctx, global, "Symbol")
      for s in JSSymbolRefs:
        let name = $s
        let val = JS_GetPropertyStr(ctx, sym, cstring(name))
        assert JS_IsSymbol(val)
        opaque.sym_refs[s] = JS_ValueToAtom(ctx, val)
        JS_FreeValue(ctx, val)
      JS_FreeValue(ctx, sym)
      for s in JSStrRefs:
        let ss = $s
        opaque.str_refs[s] = JS_NewAtomLen(ctx, cstring(ss), csize_t(ss.len))
    block:
      let arrproto = JS_GetClassProto(ctx, JS_CLASS_ARRAY)
      opaque.Array_prototype_values = JS_GetPropertyStr(ctx, arrproto,
        "values")
      JS_FreeValue(ctx, arrproto)
    block:
      let objproto = JS_GetClassProto(ctx, JS_CLASS_OBJECT)
      opaque.Object_prototype_valueOf = JS_GetPropertyStr(ctx, objproto, "valueOf")
      JS_FreeValue(ctx, objproto)
    for e in JSErrorEnum:
      let s = $e
      let err = JS_GetPropertyStr(ctx, global, cstring(s))
      opaque.err_ctors[e] = err
    JS_FreeValue(ctx, global)

  JS_SetContextOpaque(ctx, cast[pointer](opaque))
  return ctx

proc newJSContextRaw*(rt: JSRuntime): JSContext =
  result = JS_NewContextRaw(rt)

func getJSValue(argv: ptr JSValue, i: int): JSValue {.inline.} =
  cast[ptr UncheckedArray[JSValue]](argv)[i]

func getClass*(ctx: JSContext, class: string): JSClassID =
  # This function *should* never fail.
  ctx.getOpaque().creg[class]

func findClass*(ctx: JSContext, class: string): Option[JSClassID] =
  let opaque = ctx.getOpaque()
  if class in opaque.creg:
    return some(opaque.creg[class])
  return none(JSClassID)

func newJSCFunction*(ctx: JSContext, name: string, fun: JSCFunction,
    argc: int = 0, proto = JS_CFUNC_generic, magic = 0): JSValue =
  return JS_NewCFunction2(ctx, fun, cstring(name), cint(argc), proto, cint(magic))

proc free*(ctx: var JSContext) =
  var opaque = ctx.getOpaque()
  if opaque != nil:
    for a in opaque.sym_refs:
      JS_FreeAtom(ctx, a)
    for a in opaque.str_refs:
      JS_FreeAtom(ctx, a)
    for classid, v in opaque.ctors:
      JS_FreeValue(ctx, v)
    JS_FreeValue(ctx, opaque.Array_prototype_values)
    JS_FreeValue(ctx, opaque.Object_prototype_valueOf)
    for v in opaque.err_ctors:
      JS_FreeValue(ctx, v)
    GC_unref(opaque)
  JS_FreeContext(ctx)
  ctx = nil

proc free*(rt: var JSRuntime) =
  let opaque = rt.getOpaque()
  GC_unref(opaque)
  JS_FreeRuntime(rt)
  runtimes.del(runtimes.find(rt))
  rt = nil

proc setOpaque[T](ctx: JSContext, val: JSValue, opaque: T) =
  let rt = JS_GetRuntime(ctx)
  let rtOpaque = rt.getOpaque()
  let p = JS_VALUE_GET_PTR(val)
  rtOpaque.plist[cast[pointer](opaque)] = p
  JS_SetOpaque(val, cast[pointer](opaque))
  GC_ref(opaque)

proc setGlobal*[T](ctx: JSContext, global: JSValue, obj: T) =
  # Add JSValue reference.
  let p = JS_VALUE_GET_PTR(global)
  let header = cast[ptr JSRefCountHeader](p)
  inc header.ref_count
  ctx.setOpaque(global, obj)

func isGlobal*(ctx: JSContext, class: string): bool =
  assert class != ""
  return ctx.getOpaque().gclaz == class

# getOpaque, but doesn't work for global objects.
func getOpaque0*(val: JSValue): pointer =
  if JS_VALUE_GET_TAG(val) == JS_TAG_OBJECT:
    return JS_GetOpaque(val, JS_GetClassID(val))

func getGlobalOpaque*(ctx: JSContext, T: typedesc, val: JSValue = JS_UNDEFINED): Opt[T] =
  let global = JS_GetGlobalObject(ctx)
  if JS_IsUndefined(val) or val == global:
    let opaque = JS_GetOpaque(global, JS_CLASS_OBJECT)
    JS_FreeValue(ctx, global)
    return ok(cast[T](opaque))
  JS_FreeValue(ctx, global)
  return err()

func getOpaque*(ctx: JSContext, val: JSValue, class: string): pointer =
  # Unfortunately, we can't change the global object's class.
  #TODO: or maybe we can, but I'm afraid of breaking something.
  # This needs further investigation.
  if ctx.isGlobal(class):
    let global = JS_GetGlobalObject(ctx)
    let opaque = JS_GetOpaque(global, JS_CLASS_OBJECT)
    JS_FreeValue(ctx, global)
    return opaque
  return getOpaque0(val)

func getOpaque*[T: ref object](ctx: JSContext, val: JSValue): T =
  cast[T](getOpaque(ctx, val, $T))

proc setInterruptHandler*(rt: JSRuntime, cb: JSInterruptHandler, opaque: pointer = nil) =
  JS_SetInterruptHandler(rt, cb, opaque)

func toString*(ctx: JSContext, val: JSValue): Opt[string] =
  var plen: csize_t
  let outp = JS_ToCStringLen(ctx, addr plen, val) # cstring
  if outp != nil:
    var ret = newString(plen)
    if plen != 0:
      prepareMutation(ret)
      copyMem(addr ret[0], outp, plen)
    result = ok(ret)
    JS_FreeCString(ctx, outp)

proc writeException*(ctx: JSContext, s: Stream) =
  let ex = JS_GetException(ctx)
  let str = toString(ctx, ex)
  if str.issome:
    s.write(str.get & '\n')
  let stack = JS_GetPropertyStr(ctx, ex, cstring("stack"));
  if not JS_IsUndefined(stack):
    let str = toString(ctx, stack)
    if str.issome:
      s.write(str.get)
  s.flush()
  JS_FreeValue(ctx, stack)
  JS_FreeValue(ctx, ex)

proc runJSJobs*(rt: JSRuntime, err: Stream) =
  while JS_IsJobPending(rt):
    var ctx: JSContext
    let r = JS_ExecutePendingJob(rt, addr ctx)
    if r == -1:
      ctx.writeException(err)

func isInstanceOf*(ctx: JSContext, val: JSValue, class: static string): bool =
  let ctxOpaque = ctx.getOpaque()
  var classid = JS_GetClassID(val)
  let tclassid = ctxOpaque.creg[class]
  var found = false
  while true:
    if classid == tclassid:
      found = true
      break
    classid = ctxOpaque.parents[classid]
    if classid == 0:
      break
  return found

proc setProperty*(ctx: JSContext, val: JSValue, name: string, prop: JSValue) =
  if JS_SetPropertyStr(ctx, val, cstring(name), prop) <= 0:
    raise newException(Defect, "Failed to set property string: " & name)

proc setProperty*(ctx: JSContext, val: JSValue, name: string, fun: JSCFunction, argc: int = 0) =
  ctx.setProperty(val, name, ctx.newJSCFunction(name, fun, argc))

proc defineProperty*[T](ctx: JSContext, this: JSValue, name: string,
    prop: T) =
  when T is JSValue:
    if JS_DefinePropertyValueStr(ctx, this, cstring(name), prop, cint(0)) <= 0:
      raise newException(Defect, "Failed to define property string: " & name)
  else:
    defineProperty(ctx, this, name, toJS(ctx, prop))

proc definePropertyCWE*[T](ctx: JSContext, this: JSValue, name: string,
    prop: T) =
  when T is JSValue:
    if JS_DefinePropertyValueStr(ctx, this, cstring(name), prop,
        JS_PROP_C_W_E) <= 0:
      raise newException(Defect, "Failed to define property string: " & name)
  else:
    definePropertyCWE(ctx, this, name, toJS(ctx, prop))

func newJSClass*(ctx: JSContext, cdef: JSClassDefConst, tname: string,
    ctor: JSCFunction, funcs: JSFunctionList, nimt: pointer, parent: JSClassID,
    asglobal: bool, nointerface: bool, finalizer: proc(val: JSValue),
    namespace: JSValue, errid: Opt[JSErrorEnum]): JSClassID {.discardable.} =
  let rt = JS_GetRuntime(ctx)
  discard JS_NewClassID(addr result)
  var ctxOpaque = ctx.getOpaque()
  var rtOpaque = rt.getOpaque()
  if JS_NewClass(rt, result, cdef) != 0:
    raise newException(Defect, "Failed to allocate JS class: " & $cdef.class_name)
  ctxOpaque.typemap[nimt] = result
  ctxOpaque.creg[tname] = result
  ctxOpaque.parents[result] = parent
  if finalizer != nil:
    rtOpaque.fins[result] = finalizer
  var proto: JSValue
  if parent != 0:
    let parentProto = JS_GetClassProto(ctx, parent)
    proto = JS_NewObjectProtoClass(ctx, parentProto, parent)
    JS_FreeValue(ctx, parentProto)
  else:
    proto = JS_NewObject(ctx)
  if funcs.len > 0:
    # We avoid funcs being GC'ed by putting the list in rtOpaque.
    # (QuickJS uses the pointer later.)
    #TODO maybe put them in ctxOpaque instead?
    rtOpaque.flist.add(@funcs)
    JS_SetPropertyFunctionList(ctx, proto, addr rtOpaque.flist[^1][0], cint(funcs.len))
  #TODO check if this is an indexed property getter
  if cdef.exotic != nil and cdef.exotic.get_own_property != nil:
    let val = JS_DupValue(ctx, ctxOpaque.Array_prototype_values)
    doAssert JS_SetProperty(ctx, proto, ctxOpaque.sym_refs[ITERATOR], val) == 1
  let toStringTag = ctxOpaque.sym_refs[TO_STRING_TAG]
  let news = JS_NewString(ctx, cdef.class_name)
  doAssert JS_SetProperty(ctx, proto, toStringTag, news) == 1
  JS_SetClassProto(ctx, result, proto)
  if asglobal:
    let global = JS_GetGlobalObject(ctx)
    assert ctxOpaque.gclaz == ""
    ctxOpaque.gclaz = tname
    if JS_SetPrototype(ctx, global, proto) != 1:
      raise newException(Defect, "Failed to set global prototype: " & $cdef.class_name)
    JS_FreeValue(ctx, global)
  let jctor = ctx.newJSCFunction($cdef.class_name, ctor, 0, JS_CFUNC_constructor)
  JS_SetConstructor(ctx, jctor, proto)
  if errid.isSome:
    ctx.getOpaque().err_ctors[errid.get] = JS_DupValue(ctx, jctor)
  ctxOpaque.ctors[result] = JS_DupValue(ctx, jctor)
  if not nointerface:
    if JS_IsNull(namespace):
      let global = JS_GetGlobalObject(ctx)
      ctx.defineProperty(global, $cdef.class_name, jctor)
      JS_FreeValue(ctx, global)
    else:
      ctx.defineProperty(namespace, $cdef.class_name, jctor)

type FuncParam = tuple[name: string, t: NimNode, val: Option[NimNode], generic: Option[NimNode]]

func getMinArgs(params: seq[FuncParam]): int =
  for i in 0..<params.len:
    let it = params[i]
    if it[2].issome:
      return i
    let t = it.t
    if t.kind == nnkBracketExpr:
      if t.typeKind == varargs.getType().typeKind:
        assert i == params.high, "Not even nim can properly handle this..."
        return i
  return params.len

proc newEvalError*(message: string): JSError =
  return JSError(
    e: JS_EVAL_ERROR0,
    message: message
  )

proc newRangeError*(message: string): JSError =
  return JSError(
    e: JS_RANGE_ERROR0,
    message: message
  )

proc newReferenceError*(message: string): JSError =
  return JSError(
    e: JS_REFERENCE_ERROR0,
    message: message
  )

proc newSyntaxError*(message: string): JSError =
  return JSError(
    e: JS_SYNTAX_ERROR0,
    message: message
  )

proc newTypeError*(message: string): JSError =
  return JSError(
    e: JS_TYPE_ERROR0,
    message: message
  )

proc newURIError*(message: string): JSError =
  return JSError(
    e: JS_URI_ERROR0,
    message: message
  )

proc newInternalError*(message: string): JSError =
  return JSError(
    e: JS_INTERNAL_ERROR0,
    message: message
  )

proc newAggregateError*(message: string): JSError =
  return JSError(
    e: JS_AGGREGATE_ERROR0,
    message: message
  )

func fromJSString(ctx: JSContext, val: JSValue): Result[string, JSError] =
  var plen: csize_t
  let outp = JS_ToCStringLen(ctx, addr plen, val) # cstring
  if outp == nil:
    return err()
  var ret = newString(plen)
  if plen != 0:
    prepareMutation(ret)
    copyMem(addr ret[0], outp, plen)
  JS_FreeCString(ctx, outp)
  return ok(ret)

func fromJSInt[T: SomeInteger](ctx: JSContext, val: JSValue):
    Result[T, JSError] =
  if not JS_IsNumber(val):
    return err()
  when T is int:
    # Always int32, so we don't risk 32-bit only breakage.
    # If int64 is needed, specify it explicitly.
    var ret: int32
    if JS_ToInt32(ctx, addr ret, val) < 0:
      return err()
    return ok(int(ret))
  elif T is uint:
    var ret: uint32
    if JS_ToUint32(ctx, addr ret, val) < 0:
      return err()
    return ok(uint(ret))
  elif T is int32:
    var ret: int32
    if JS_ToInt32(ctx, addr ret, val) < 0:
      return err()
    return ok(ret)
  elif T is int64:
    var ret: int64
    if JS_ToInt64(ctx, addr ret, val) < 0:
      return err()
    return ok(ret)
  elif T is uint32:
    var ret: uint32
    if JS_ToUint32(ctx, addr ret, val) < 0:
      return err()
    return ok(ret)
  elif T is uint64:
    var ret: uint32
    if JS_ToUint32(ctx, addr ret, val) < 0:
      return err()
    return ok(cast[uint64](ret))

proc fromJSFloat[T: SomeFloat](ctx: JSContext, val: JSValue):
    Result[T, JSError] =
  if not JS_IsNumber(val):
    return err()
  var f64: float64
  if JS_ToFloat64(ctx, addr f64, val) < 0:
    return err()
  return ok(cast[T](f64))

proc fromJS*[T](ctx: JSContext, val: JSValue): Result[T, JSError]

macro len(t: type tuple): int =
  let i = t.getType()[1].len - 1 # - tuple
  newLit(i)

macro fromJSTupleBody(a: tuple) =
  let len = a.getType().len - 1
  let done = ident("done")
  result = newStmtList(quote do:
    var `done`: bool)
  for i in 0..<len:
    result.add(quote do:
      let next = JS_Call(ctx, next_method, it, 0, nil)
      if JS_IsException(next):
        return err()
      defer: JS_FreeValue(ctx, next)
      let doneVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[DONE])
      if JS_IsException(doneVal):
        return err()
      defer: JS_FreeValue(ctx, doneVal)
      `done` = ?fromJS[bool](ctx, doneVal)
      if `done`:
        JS_ThrowTypeError(ctx, "Too few arguments in sequence (got %d, expected %d)", `i`, `len`)
        return err()
      let valueVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[VALUE])
      if JS_IsException(valueVal):
        return err()
      defer: JS_FreeValue(ctx, valueVal)
      let genericRes = fromJS[typeof(`a`[`i`])](ctx, valueVal)
      if genericRes.isErr: # exception
        return err()
      `a`[`i`] = genericRes.get
    )
    if i == len - 1:
      result.add(quote do:
        let next = JS_Call(ctx, next_method, it, 0, nil)
        if JS_IsException(next):
          return err()
        defer: JS_FreeValue(ctx, next)
        let doneVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[DONE])
        `done` = ?fromJS[bool](ctx, doneVal)
        var i = `i`
        # we're emulating a sequence, so we must query all remaining parameters too:
        while not `done`:
          inc i
          let next = JS_Call(ctx, next_method, it, 0, nil)
          if JS_IsException(next):
            return err()
          defer: JS_FreeValue(ctx, next)
          let doneVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[DONE])
          if JS_IsException(doneVal):
            return err()
          defer: JS_FreeValue(ctx, doneVal)
          `done` = ?fromJS[bool](ctx, doneVal)
          if `done`:
            let msg = "Too many arguments in sequence (got " & $i &
              ", expected " & $`len` & ")"
            return err(newTypeError(msg))
          JS_FreeValue(ctx, JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[VALUE]))
      )

proc fromJSTuple[T: tuple](ctx: JSContext, val: JSValue): Result[T, JSError] =
  let itprop = JS_GetProperty(ctx, val, ctx.getOpaque().sym_refs[ITERATOR])
  if JS_IsException(itprop):
    return err()
  defer: JS_FreeValue(ctx, itprop)
  let it = JS_Call(ctx, itprop, val, 0, nil)
  if JS_IsException(it):
    return err()
  defer: JS_FreeValue(ctx, it)
  let next_method = JS_GetProperty(ctx, it, ctx.getOpaque().str_refs[NEXT])
  if JS_IsException(next_method):
    return err()
  defer: JS_FreeValue(ctx, next_method)
  var x: T
  fromJSTupleBody(x)
  return ok(x)

proc fromJSSeq[T](ctx: JSContext, val: JSValue): Result[seq[T], JSError] =
  let itprop = JS_GetProperty(ctx, val, ctx.getOpaque().sym_refs[ITERATOR])
  if JS_IsException(itprop):
    return err()
  defer: JS_FreeValue(ctx, itprop)
  let it = JS_Call(ctx, itprop, val, 0, nil)
  if JS_IsException(it):
    return err()
  defer: JS_FreeValue(ctx, it)
  let next_method = JS_GetProperty(ctx, it, ctx.getOpaque().str_refs[NEXT])
  if JS_IsException(next_method):
    return err()
  defer: JS_FreeValue(ctx, next_method)
  var s = newSeq[T]()
  while true:
    let next = JS_Call(ctx, next_method, it, 0, nil)
    if JS_IsException(next):
      return err()
    defer: JS_FreeValue(ctx, next)
    let doneVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[DONE])
    if JS_IsException(doneVal):
      return err()
    defer: JS_FreeValue(ctx, doneVal)
    let done = ?fromJS[bool](ctx, doneVal)
    if done:
      break
    let valueVal = JS_GetProperty(ctx, next, ctx.getOpaque().str_refs[VALUE])
    if JS_IsException(valueVal):
      return err()
    defer: JS_FreeValue(ctx, valueVal)
    let genericRes = fromJS[typeof(s[0])](ctx, valueVal)
    if genericRes.isnone: # exception
      return err()
    s.add(genericRes.get)
  return ok(s)

proc fromJSSet[T](ctx: JSContext, val: JSValue): Opt[set[T]] =
  let itprop = JS_GetProperty(ctx, val, ctx.getOpaque().sym_refs[ITERATOR])
  if JS_IsException(itprop):
    return err()
  defer: JS_FreeValue(ctx, itprop)
  let it = JS_Call(ctx, itprop, val, 0, nil)
  if JS_IsException(it):
    return err()
  defer: JS_FreeValue(ctx, it)
  let next_method = JS_GetProperty(ctx, it, ctx.getOpaque().str_refs[NEXT])
  if JS_IsException(next_method):
    return err()
  defer: JS_FreeValue(ctx, next_method)
  var s: set[T]
  while true:
    let next = JS_Call(ctx, next_method, it, 0, nil)
    if JS_IsException(next):
      return err()
    defer: JS_FreeValue(ctx, next)
    let doneVal = JS_GetProperty(ctx, next, ctx.getOpaque().done)
    if JS_IsException(doneVal):
      return err()
    defer: JS_FreeValue(ctx, doneVal)
    let done = ?fromJS[bool](ctx, doneVal)
    if done:
      break
    let valueVal = JS_GetProperty(ctx, next, ctx.getOpaque().value)
    if JS_IsException(valueVal):
      return err()
    defer: JS_FreeValue(ctx, valueVal)
    let genericRes = ?fromJS[typeof(s.items)](ctx, valueVal)
    s.incl(genericRes)
  return ok(s)

proc fromJSTable[A, B](ctx: JSContext, val: JSValue):
    Result[Table[A, B], JSError] =
  var ptab: ptr JSPropertyEnum
  var plen: uint32
  let flags = cint(JS_GPN_STRING_MASK)
  if JS_GetOwnPropertyNames(ctx, addr ptab, addr plen, val, flags) == -1:
    # exception
    return err()
  defer:
    for i in 0..<plen:
      let prop = cast[ptr JSPropertyEnum](cast[int](ptab) + sizeof(ptab[]) * int(i))
      JS_FreeAtom(ctx, prop.atom)
    js_free(ctx, ptab)
  var res = Table[A, B]()
  for i in 0..<plen:
    let prop = cast[ptr JSPropertyEnum](cast[int](ptab) + sizeof(ptab[]) * int(i))
    let atom = prop.atom
    let k = JS_AtomToValue(ctx, atom)
    defer: JS_FreeValue(ctx, k)
    let kn = ?fromJS[A](ctx, k)
    let v = JS_GetProperty(ctx, val, atom)
    defer: JS_FreeValue(ctx, v)
    let vn = ?fromJS[B](ctx, v)
    res[kn] = vn
  return ok(res)

proc toJS*(ctx: JSContext, s: cstring): JSValue
proc toJS*(ctx: JSContext, s: string): JSValue
proc toJS(ctx: JSContext, r: Rune): JSValue
proc toJS*(ctx: JSContext, n: int64): JSValue
proc toJS*(ctx: JSContext, n: int32): JSValue
proc toJS*(ctx: JSContext, n: int): JSValue
proc toJS*(ctx: JSContext, n: uint16): JSValue
proc toJS*(ctx: JSContext, n: uint32): JSValue
proc toJS*(ctx: JSContext, n: uint64): JSValue
proc toJS(ctx: JSContext, n: SomeFloat): JSValue
proc toJS*(ctx: JSContext, b: bool): JSValue
proc toJS[U, V](ctx: JSContext, t: Table[U, V]): JSValue
proc toJS*(ctx: JSContext, opt: Option): JSValue
proc toJS[T, E](ctx: JSContext, opt: Result[T, E]): JSValue
proc toJS(ctx: JSContext, s: seq): JSValue
proc toJS(ctx: JSContext, e: enum): JSValue
proc toJS(ctx: JSContext, j: JSValue): JSValue
proc toJS[T](ctx: JSContext, promise: Promise[T]): JSValue
proc toJS[T, E](ctx: JSContext, promise: Promise[Result[T, E]]): JSValue
proc toJS(ctx: JSContext, promise: EmptyPromise): JSValue
proc toJSRefObj(ctx: JSContext, obj: ref object): JSValue
proc toJS*(ctx: JSContext, obj: ref object): JSValue
proc toJS*(ctx: JSContext, err: JSError): JSValue
proc toJS*(ctx: JSContext, f: JSCFunction): JSValue

#TODO varargs
proc fromJSFunction1[T, U](ctx: JSContext, val: JSValue):
    proc(x: U): Result[T, JSError] =
  return proc(x: U): Result[T, JSError] =
    var arg1 = toJS(ctx, x)
    let ret = JS_Call(ctx, val, JS_UNDEFINED, 1, addr arg1)
    return fromJS[T](ctx, ret)

macro unpackReturnType(f: typed) =
  var x = f.getTypeImpl()
  while x.kind == nnkBracketExpr and x.len == 2:
    x = x[1].getTypeImpl()
  let params = x.findChild(it.kind == nnkFormalParams)
  let rv = params[0]
  doAssert rv[0].strVal == "Result"
  let rvv = rv[1]
  result = quote do: `rvv`

macro unpackArg0(f: typed) =
  var x = f.getTypeImpl()
  while x.kind == nnkBracketExpr and x.len == 2:
    x = x[1].getTypeImpl()
  let params = x.findChild(it.kind == nnkFormalParams)
  let rv = params[1]
  assert rv.kind == nnkIdentDefs
  let rvv = rv[1]
  result = quote do: `rvv`

proc fromJSChar(ctx: JSContext, val: JSValue): Opt[char] =
  let s = ?toString(ctx, val)
  if s.len > 1:
    return err()
  return ok(s[0])

proc fromJSRune(ctx: JSContext, val: JSValue): Opt[Rune] =
  let s = ?toString(ctx, val)
  var i = 0
  var r: Rune
  fastRuneAt(s, i, r)
  if i < s.len:
    return err()
  return ok(r)

template optionType[T](o: type Option[T]): auto =
  T

# wrap
proc fromJSOption[T](ctx: JSContext, val: JSValue): Result[Option[T], JSError] =
  if JS_IsUndefined(val):
    #TODO what about null?
    return err()
  let res = ?fromJS[T](ctx, val)
  return ok(some(res))

# wrap
proc fromJSOpt[T](ctx: JSContext, val: JSValue): Result[T, JSError] =
  if JS_IsUndefined(val):
    #TODO what about null?
    return err()
  let res = fromJS[T.valType](ctx, val)
  if res.isErr:
    return ok(opt(T.valType))
  return ok(opt(res.get))

proc fromJSBool(ctx: JSContext, val: JSValue): Result[bool, JSError] =
  let ret = JS_ToBool(ctx, val)
  if ret == -1: # exception
    return err()
  if ret == 0:
    return ok(false)
  return ok(true)

proc fromJSEnum[T: enum](ctx: JSContext, val: JSValue): Result[T, JSError] =
  if JS_IsException(val):
    return err()
  let s = ?toString(ctx, val)
  try:
    return ok(parseEnum[T](s))
  except ValueError:
    return err(newTypeError("`" & s &
      "' is not a valid value for enumeration " & $T))

proc fromJSObject[T: ref object](ctx: JSContext, val: JSValue): Result[T, JSError] =
  if JS_IsException(val):
    return err(nil)
  if JS_IsNull(val):
    return ok(T(nil))
  const t = $T
  let ctxOpaque = ctx.getOpaque()
  if ctxOpaque.gclaz == t:
    return ok(?getGlobalOpaque(ctx, T, val))
  if not JS_IsObject(val):
    return err(newTypeError("Value is not an object"))
  if not isInstanceOf(ctx, val, t):
    const errmsg = t & " expected"
    JS_ThrowTypeError(ctx, errmsg)
    return err(newTypeError(errmsg))
  let classid = JS_GetClassID(val)
  let op = cast[T](JS_GetOpaque(val, classid))
  return ok(cast[T](op))

proc fromJS*[T](ctx: JSContext, val: JSValue): Result[T, JSError] =
  when T is string:
    return fromJSString(ctx, val)
  elif T is char:
    return fromJSChar(ctx, val)
  elif T is Rune:
    return fromJSRune(ctx, val)
  elif T is (proc):
    return ok(fromJSFunction1[typeof(unpackReturnType(T)),
      typeof(unpackArg0(T))](ctx, val))
  elif T is Option:
    return fromJSOption[optionType(T)](ctx, val)
  elif T is Opt: # unwrap
    return fromJSOpt[T](ctx, val)
  elif T is seq:
    return fromJSSeq[typeof(result.get.items)](ctx, val)
  elif T is set:
    return fromJSSet[typeof(result.get.items)](ctx, val)
  elif T is tuple:
    return fromJSTuple[T](ctx, val)
  elif T is bool:
    return fromJSBool(ctx, val)
  elif typeof(result).valType is Table:
    return fromJSTable[typeof(result.get.keys),
      typeof(result.get.values)](ctx, val)
  elif T is SomeInteger:
    return fromJSInt[T](ctx, val)
  elif T is SomeFloat:
    return fromJSFloat[T](ctx, val)
  elif T is enum:
    return fromJSEnum[T](ctx, val)
  elif T is JSValue:
    return ok(val)
  elif T is ref object:
    return fromJSObject[T](ctx, val)
  else:
    static:
      doAssert false

const JS_ATOM_TAG_INT = cuint(1u32 shl 31)

func JS_IsNumber(v: JSAtom): JS_BOOL =
  return (cast[cuint](v) and JS_ATOM_TAG_INT) != 0

func fromJS[T: string|uint32](ctx: JSContext, atom: JSAtom): Opt[T] =
  when T is SomeNumber:
    if JS_IsNumber(atom):
      return ok(T(cast[uint32](atom) and (not JS_ATOM_TAG_INT)))
  else:
    let val = JS_AtomToValue(ctx, atom)
    return toString(ctx, val)

proc getJSFunction*[T, U](ctx: JSContext, val: JSValue):
    (proc(x: T): Result[U, JSError]) =
  return fromJSFunction1[T, U](ctx, val)

proc toJS*(ctx: JSContext, s: cstring): JSValue =
  return JS_NewString(ctx, s)

proc toJS*(ctx: JSContext, s: string): JSValue =
  return toJS(ctx, cstring(s))

proc toJS(ctx: JSContext, r: Rune): JSValue =
  return toJS(ctx, $r)

proc toJS*(ctx: JSContext, n: int32): JSValue =
  return JS_NewInt32(ctx, n)

proc toJS*(ctx: JSContext, n: int64): JSValue =
  return JS_NewInt64(ctx, n)

# Always int32, so we don't risk 32-bit only breakage.
proc toJS*(ctx: JSContext, n: int): JSValue =
  return toJS(ctx, int32(n))

proc toJS*(ctx: JSContext, n: uint16): JSValue =
  return JS_NewUint32(ctx, uint32(n))

proc toJS*(ctx: JSContext, n: uint32): JSValue =
  return JS_NewUint32(ctx, n)

proc toJS*(ctx: JSContext, n: uint64): JSValue =
  #TODO this is incorrect
  return JS_NewFloat64(ctx, float64(n))

proc toJS(ctx: JSContext, n: SomeFloat): JSValue =
  return JS_NewFloat64(ctx, float64(n))

proc toJS*(ctx: JSContext, b: bool): JSValue =
  return JS_NewBool(ctx, b)

proc toJS[U, V](ctx: JSContext, t: Table[U, V]): JSValue =
  let obj = JS_NewObject(ctx)
  if not JS_IsException(obj):
    for k, v in t:
      setProperty(ctx, obj, k, toJS(ctx, v))
  return obj

proc toJS*(ctx: JSContext, opt: Option): JSValue =
  if opt.isSome:
    return toJS(ctx, opt.get)
  return JS_NULL

proc toJS[T, E](ctx: JSContext, opt: Result[T, E]): JSValue =
  if opt.isSome:
    when not (T is void):
      return toJS(ctx, opt.get)
    else:
      return JS_UNDEFINED
  else:
    when not (E is void):
      let res = toJS(ctx, opt.error)
      if not JS_IsNull(res):
        return JS_Throw(ctx, res)
    else:
      return JS_NULL

proc toJS(ctx: JSContext, s: seq): JSValue =
  let a = JS_NewArray(ctx)
  if not JS_IsException(a):
    for i in 0..s.high:
      let j = toJS(ctx, s[i])
      if JS_IsException(j):
        return j
      if JS_DefinePropertyValueInt64(ctx, a, int64(i), j, JS_PROP_C_W_E or JS_PROP_THROW) < 0:
        return JS_EXCEPTION
  return a

proc getTypePtr[T](x: T): pointer =
  when T is RootRef:
    # I'm so sorry.
    # (This dereferences the object's first member, m_type. Probably.)
    return cast[ptr pointer](x)[]
  else:
    return getTypeInfo(x)

proc toJSRefObj(ctx: JSContext, obj: ref object): JSValue =
  if obj == nil:
    return JS_NULL
  let op = JS_GetRuntime(ctx).getOpaque()
  let p = cast[pointer](obj)
  if p in op.plist:
    # a JSValue already points to this object.
    return JS_DupValue(ctx, JS_MKPTR(JS_TAG_OBJECT, op.plist[p]))
  let clazz = ctx.getOpaque().typemap[getTypePtr(obj)]
  let jsObj = JS_NewObjectClass(ctx, clazz)
  setOpaque(ctx, jsObj, obj)
  return jsObj

proc toJS*(ctx: JSContext, obj: ref object): JSValue =
  return toJSRefObj(ctx, obj)

proc toJS(ctx: JSContext, e: enum): JSValue =
  return toJS(ctx, $e)

proc toJS(ctx: JSContext, j: JSValue): JSValue =
  return j

proc toJS(ctx: JSContext, promise: EmptyPromise): JSValue =
  var resolving_funcs: array[2, JSValue]
  let jsPromise = JS_NewPromiseCapability(ctx, addr resolving_funcs[0])
  if JS_IsException(jsPromise):
    return JS_EXCEPTION
  promise.then(proc() =
    var x = JS_UNDEFINED
    let res = JS_Call(ctx, resolving_funcs[0], JS_UNDEFINED, 1, addr x)
    JS_FreeValue(ctx, res)
    JS_FreeValue(ctx, resolving_funcs[0])
    JS_FreeValue(ctx, resolving_funcs[1]))
  return jsPromise

proc toJS[T](ctx: JSContext, promise: Promise[T]): JSValue =
  var resolving_funcs: array[2, JSValue]
  let jsPromise = JS_NewPromiseCapability(ctx, addr resolving_funcs[0])
  if JS_IsException(jsPromise):
    return JS_EXCEPTION
  promise.then(proc(x: T) =
    var x = toJS(ctx, x)
    let res = JS_Call(ctx, resolving_funcs[0], JS_UNDEFINED, 1, addr x)
    JS_FreeValue(ctx, res)
    JS_FreeValue(ctx, x)
    JS_FreeValue(ctx, resolving_funcs[0])
    JS_FreeValue(ctx, resolving_funcs[1]))
  return jsPromise

proc toJS[T, E](ctx: JSContext, promise: Promise[Result[T, E]]): JSValue =
  var resolving_funcs: array[2, JSValue]
  let jsPromise = JS_NewPromiseCapability(ctx, addr resolving_funcs[0])
  if JS_IsException(jsPromise):
    return JS_EXCEPTION
  promise.then(proc(x: Result[T, E]) =
    if x.isOk:
      let x = when T is void:
        JS_UNDEFINED
      else:
        toJS(ctx, x.get)
      let res = JS_Call(ctx, resolving_funcs[0], JS_UNDEFINED, 1, unsafeAddr x)
      JS_FreeValue(ctx, res)
      JS_FreeValue(ctx, x)
    else: # err
      let x = when E is void:
        JS_UNDEFINED
      else:
        toJS(ctx, x.error)
      let res = JS_Call(ctx, resolving_funcs[1], JS_UNDEFINED, 1, unsafeAddr x)
      JS_FreeValue(ctx, res)
      JS_FreeValue(ctx, x)
    JS_FreeValue(ctx, resolving_funcs[0])
    JS_FreeValue(ctx, resolving_funcs[1]))
  return jsPromise

proc toJS*(ctx: JSContext, err: JSError): JSValue =
  if err.e notin QuickJSErrors:
    return toJSRefObj(ctx, err)
  var msg = toJS(ctx, err.message)
  if JS_IsException(msg):
    return msg
  let ctor = ctx.getOpaque().err_ctors[err.e]
  return JS_CallConstructor(ctx, ctor, 1, addr msg)

proc toJS*(ctx: JSContext, f: JSCFunction): JSValue =
  return ctx.newJSCFunction("", f)

proc defineConsts*[T](ctx: JSContext, classid: JSClassID,
    consts: static openarray[(string, T)]) =
  let proto = ctx.getOpaque().ctors[classid]
  for (k, v) in consts:
    ctx.defineProperty(proto, k, v)

proc defineConsts*(ctx: JSContext, classid: JSClassID,
    consts: typedesc[enum], astype: typedesc) =
  let proto = ctx.getOpaque().ctors[classid]
  for e in consts:
    ctx.defineProperty(proto, $e, astype(e))

type
  JSFuncGenerator = object
    t: BoundFunctionType
    original: NimNode
    copied: NimNode
    thisname: Option[string]
    funcName: string
    generics: Table[string, seq[NimNode]]
    funcParams: seq[FuncParam]
    passCtx: bool
    thisType: string
    returnType: Option[NimNode]
    newName: NimNode
    newBranchList: seq[NimNode]
    errval: NimNode # JS_EXCEPTION or -1
    dielabel: NimNode # die: didn't match parameters, but could still match other ones
    jsFunCallLists: seq[NimNode]
    jsFunCallList: NimNode
    jsFunCall: NimNode
    jsCallAndRet: NimNode
    minArgs: int
    actualMinArgs: int # minArgs without JSContext
    i: int # nim parameters accounted for
    j: int # js parameters accounted for (not including fix ones, e.g. `this')
    res: NimNode

  BoundFunction = object
    t: BoundFunctionType
    name: string
    id: NimNode
    magic: uint16

  BoundFunctionType = enum
    FUNCTION = "js_func"
    CONSTRUCTOR = "js_ctor"
    GETTER = "js_get"
    SETTER = "js_set"
    PROPERTY_GET = "js_prop_get"
    PROPERTY_HAS = "js_prop_has"
    FINALIZER = "js_fin"

var BoundFunctions {.compileTime.}: Table[string, seq[BoundFunction]]

proc getGenerics(fun: NimNode): Table[string, seq[NimNode]] =
  var node = fun.findChild(it.kind == nnkBracket)
  if node.kind == nnkNilLit:
    return # no bracket
  node = node.findChild(it.kind == nnkGenericParams)
  if node.kind == nnkNilLit:
    return # no generics
  node = node.findChild(it.kind == nnkIdentDefs)
  var stack: seq[NimNode]
  for i in countdown(node.len - 1, 0): stack.add(node[i])
  var gen_name: NimNode
  var gen_types: seq[NimNode]
  template add_gen =
    if gen_name != nil:
      assert gen_types.len != 0
      result[gen_name.strVal] = gen_types
      gen_types.setLen(0)

  while stack.len > 0:
    let node = stack.pop()
    case node.kind
    of nnkIdent:
      add_gen
      gen_name = node
    of nnkSym:
      assert gen_name != nil
      gen_types.add(node)
    of nnkInfix:
      assert node[0].eqIdent(ident("|")) or node[0].eqIdent(ident("or")), "Only OR generics are supported."
      for i in countdown(node.len - 1, 1): stack.add(node[i]) # except infix ident
    of nnkBracketExpr:
      gen_types.add(node)
    else:
      discard
  add_gen

proc getParams(fun: NimNode): seq[FuncParam] =
  let formalParams = fun.findChild(it.kind == nnkFormalParams)
  var funcParams: seq[FuncParam]
  var returnType = none(NimNode)
  if formalParams[0].kind != nnkEmpty:
    returnType = some(formalParams[0])
  for i in 1..<fun.params.len:
    let it = formalParams[i]
    let tt = it[^2]
    var t: NimNode
    if it[^2].kind != nnkEmpty:
      t = `tt`
    elif it[^1].kind != nnkEmpty:
      let x = it[^1]
      t = quote do:
        typeof(`x`)
    else:
      error("?? " & treeRepr(it))
    let val = if it[^1].kind != nnkEmpty:
      let x = it[^1]
      some(newPar(x))
    else:
      none(NimNode)
    var g = none(NimNode)
    for i in 0 ..< it.len - 2:
      let name = $it[i]
      funcParams.add((name, t, val, g))
  funcParams

proc getReturn(fun: NimNode): Option[NimNode] =
  let formalParams = fun.findChild(it.kind == nnkFormalParams)
  if formalParams[0].kind != nnkEmpty:
    some(formalParams[0])
  else:
    none(NimNode)

template getJSParams(): untyped =
  [
    (quote do: JSValue),
    newIdentDefs(ident("ctx"), quote do: JSContext),
    newIdentDefs(ident("this"), quote do: JSValue),
    newIdentDefs(ident("argc"), quote do: cint),
    newIdentDefs(ident("argv"), quote do: ptr JSValue)
  ]

template getJSGetterParams(): untyped =
  [
    (quote do: JSValue),
    newIdentDefs(ident("ctx"), quote do: JSContext),
    newIdentDefs(ident("this"), quote do: JSValue),
  ]

template getJSGetPropParams(): untyped =
  [
    (quote do: cint),
    newIdentDefs(ident("ctx"), quote do: JSContext),
    newIdentDefs(ident("desc"), quote do: ptr JSPropertyDescriptor),
    newIdentDefs(ident("obj"), quote do: JSValue),
    newIdentDefs(ident("prop"), quote do: JSAtom),
  ]

template getJSHasPropParams(): untyped =
  [
    (quote do: cint),
    newIdentDefs(ident("ctx"), quote do: JSContext),
    newIdentDefs(ident("obj"), quote do: JSValue),
    newIdentDefs(ident("atom"), quote do: JSAtom),
  ]


template getJSSetterParams(): untyped =
  [
    (quote do: JSValue),
    newIdentDefs(ident("ctx"), quote do: JSContext),
    newIdentDefs(ident("this"), quote do: JSValue),
    newIdentDefs(ident("val"), quote do: JSValue),
  ]

template fromJS_or_return*(t, ctx, val: untyped): untyped =
  (
    if JS_IsException(val):
      return JS_EXCEPTION
    let x = fromJS[t](ctx, val)
    if x.isErr:
      if x.error == nil:
        return JS_EXCEPTION
      return toJS(ctx, x.error)
    x.get
  )

template fromJS_or_die*(t, ctx, val, ev, dl: untyped): untyped =
  when not (typeof(val) is JSAtom):
    if JS_IsException(val):
      return ev
  let x = fromJS[t](ctx, val)
  if x.isNone:
    break dl
  x.get

proc addParam2(gen: var JSFuncGenerator, s, t, val: NimNode, fallback: NimNode = nil) =
  let ev = gen.errval
  let dl = gen.dielabel
  let stmt = quote do:
    fromJS_or_die(`t`, ctx, `val`, `ev`, `dl`)
  for i in 0..gen.jsFunCallLists.high:
    if fallback == nil:
      gen.jsFunCallLists[i].add(newLetStmt(s, stmt))
    else:
      let j = gen.j
      gen.jsFunCallLists[i].add(newLetStmt(s, quote do:
        if `j` < argc: `stmt` else: `fallback`))

proc addValueParam(gen: var JSFuncGenerator, s, t: NimNode, fallback: NimNode = nil) =
  let j = gen.j
  gen.addParam2(s, t, quote do: getJSValue(argv, `j`), fallback)

proc addUnionParamBranch(gen: var JSFuncGenerator, query, newBranch: NimNode, fallback: NimNode = nil) =
  let i = gen.i
  let query = if fallback == nil: query else:
    quote do: (`i` < argc and `query`)
  let newBranch = newStmtList(newBranch)
  for i in 0..gen.jsFunCallLists.high:
    var ifstmt = newIfStmt((query, newBranch))
    let oldBranch = newStmtList()
    ifstmt.add(newTree(nnkElse, oldBranch))
    gen.jsFunCallLists[i].add(ifstmt)
    gen.jsFunCallLists[i] = oldBranch
  gen.newBranchList.add(newBranch)

func isSequence*(ctx: JSContext, o: JSValue): bool =
  if not JS_IsObject(o):
    return false
  let prop = JS_GetProperty(ctx, o, ctx.getOpaque().sym_refs[ITERATOR])
  # prop can't be exception (throws_ref_error is 0 and tag is object)
  result = not JS_IsUndefined(prop)
  JS_FreeValue(ctx, prop)

proc addUnionParam0(gen: var JSFuncGenerator, tt: NimNode, s: NimNode, val: NimNode, fallback: NimNode = nil) =
  # Union types.
  #TODO quite a few types are still missing.
  let flattened = gen.generics[tt.strVal] # flattened member types
  var tableg = none(NimNode)
  var seqg = none(NimNode)
  var numg = none(NimNode)
  var objg = none(NimNode)
  var hasString = false
  var hasJSValue = false
  var hasBoolean = false
  let ev = gen.errval
  let dl = gen.dielabel
  for g in flattened:
    if g.len > 0 and g[0] == Table.getType():
      tableg = some(g)
    elif g.typekind == ntySequence:
      seqg = some(g)
    elif g == string.getTypeInst():
      hasString = true
    elif g == JSValue.getTypeInst():
      hasJSValue = true
    elif g == bool.getTypeInst():
      hasBoolean = true
    elif g == int.getTypeInst(): #TODO should be SomeNumber
      numg = some(g)
    elif g.getTypeInst().getTypeImpl().kind == nnkRefTy:
      # Assume it's ref object.
      objg = some(g)
    else:
      error("Type not supported yet")

  # 5. If V is a platform object, then:
  if objg.isSome:
    let t = objg.get
    let x = ident("x")
    let query = quote do:
      let `x` = fromJS[`t`](ctx, `val`)
      `x`.isOk
    gen.addUnionParamBranch(query, quote do:
      let `s` = `x`.get,
      fallback)
  # 10. If Type(V) is Object, then:
  # Sequence:
  if seqg.issome:
    let query = quote do:
      isSequence(ctx, `val`)
    let a = seqg.get[1]
    gen.addUnionParamBranch(query, quote do:
      let `s` = fromJS_or_die(seq[`a`], ctx, `val`, `ev`, `dl`),
      fallback)
  # Record:
  if tableg.issome:
    let a = tableg.get[1]
    let b = tableg.get[2]
    let query = quote do:
      JS_IsObject(`val`)
    gen.addUnionParamBranch(query, quote do:
      let `s` = fromJS_or_die(Table[`a`, `b`], ctx, `val`, `ev`, `dl`),
      fallback)
  # Object (JSObject variant):
  #TODO non-JS objects (i.e. ref object)
  if hasJSValue:
    let query = quote do:
      JS_IsObject(`val`)
    gen.addUnionParamBranch(query, quote do:
      let `s` = fromJS_or_die(JSValue, ctx, `val`, `ev`, `dl`),
      fallback)
  # 11. If Type(V) is Boolean, then:
  if hasBoolean:
    let query = quote do:
      JS_IsBool(`val`)
    gen.addUnionParamBranch(query, quote do:
      let `s` = fromJS_or_die(bool, ctx, `val`, `ev`, `dl`),
      fallback)
  # 12. If Type(V) is Number, then:
  if numg.isSome:
    let ng = numg.get
    let query = quote do:
      JS_IsNumber(`val`)
    gen.addUnionParamBranch(query, quote do:
      let `s` = fromJS_or_die(`ng`, ctx, `val`, `ev`, `dl`),
      fallback)
  # 14. If types includes a string type, then return the result of converting V
  # to that type.
  if hasString:
    gen.addParam2(s, string.getType(), quote do: `val`, fallback)
  # 16. If types includes a numeric type, then return the result of converting
  # V to that numeric type.
  elif numg.isSome:
    gen.addParam2(s, numg.get.getType(), quote do: `val`, fallback)
  # 17. If types includes boolean, then return the result of converting V to
  # boolean.
  elif hasBoolean:
    gen.addParam2(s, bool.getType(), quote do: `val`, fallback)
  # 19. Throw a TypeError.
  else:
    gen.addParam2(s, string.getType(), quote do:
      if true:
        discard JS_ThrowTypeError(ctx, "No match for union type")
        return `ev`
      JS_NULL, fallback)

  for branch in gen.newBranchList:
    gen.jsFunCallLists.add(branch)
  gen.newBranchList.setLen(0)

proc addUnionParam(gen: var JSFuncGenerator, tt: NimNode, s: NimNode, fallback: NimNode = nil) =
  let j = gen.j
  gen.addUnionParam0(tt, s, quote do: getJSValue(argv, `j`), fallback)

proc addFixParam(gen: var JSFuncGenerator, name: string) =
  let s = ident("arg_" & $gen.i)
  let t = gen.funcParams[gen.i][1]
  let id = ident(name)
  if t.typeKind == ntyGenericParam:
    gen.addUnionParam0(t, s, id)
  else:
    gen.addParam2(s, t, id)
  if gen.jsFunCall != nil:
    gen.jsFunCall.add(s)
  inc gen.i

proc addRequiredParams(gen: var JSFuncGenerator) =
  while gen.i < gen.minArgs:
    let s = ident("arg_" & $gen.i)
    let tt = gen.funcParams[gen.i][1]
    if tt.typeKind == ntyGenericParam:
      gen.addUnionParam(tt, s)
    else:
      gen.addValueParam(s, tt)
    if gen.jsFunCall != nil:
      gen.jsFunCall.add(s)
    inc gen.j
    inc gen.i

proc addOptionalParams(gen: var JSFuncGenerator) =
  while gen.i < gen.funcParams.len:
    let j = gen.j
    let s = ident("arg_" & $gen.i)
    let tt = gen.funcParams[gen.i][1]
    if tt.typeKind == varargs.getType().typeKind: # pray it's not a generic...
      let vt = tt[1].getType()
      for i in 0..gen.jsFunCallLists.high:
        gen.jsFunCallLists[i].add(newLetStmt(s, quote do:
          (
            var valist: seq[`vt`]
            for i in `j`..<argc:
              let it = fromJS_or_return(`vt`, ctx, getJSValue(argv, i))
              valist.add(it)
            valist
          )
        ))
    else:
      if gen.funcParams[gen.i][2].isNone:
        error("No fallback value. Maybe a non-optional parameter follows an " &
          "optional parameter?")
      let fallback = gen.funcParams[gen.i][2].get
      if tt.typeKind == ntyGenericParam:
        gen.addUnionParam(tt, s, fallback)
      else:
        gen.addValueParam(s, tt, fallback)
    if gen.jsFunCall != nil:
      gen.jsFunCall.add(s)
    inc gen.j
    inc gen.i

proc finishFunCallList(gen: var JSFuncGenerator) =
  for branch in gen.jsFunCallLists:
    branch.add(gen.jsFunCall)

var js_funcs {.compileTime.}: Table[string, JSFuncGenerator]
var existing_funcs {.compileTime.}: HashSet[string]
var js_dtors {.compileTime.}: HashSet[string]

proc registerFunction(typ: string, t: BoundFunctionType, name: string, id: NimNode, magic: uint16 = 0) =
  let nf = BoundFunction(t: t, name: name, id: id, magic: magic)
  if typ notin BoundFunctions:
    BoundFunctions[typ] = @[nf]
  else:
    BoundFunctions[typ].add(nf)
  existing_funcs.incl(id.strVal)

proc registerConstructor(gen: JSFuncGenerator) =
  registerFunction(gen.thisType, gen.t, gen.funcName, gen.newName)
  js_funcs[gen.funcName] = gen

proc registerFunction(gen: JSFuncGenerator) =
  registerFunction(gen.thisType, gen.t, gen.funcName, gen.newName)

var js_errors {.compileTime.}: Table[string, seq[string]]

export JS_ThrowTypeError, JS_ThrowRangeError, JS_ThrowSyntaxError,
       JS_ThrowInternalError, JS_ThrowReferenceError

proc newJSProcBody(gen: var JSFuncGenerator, isva: bool): NimNode =
  let tt = gen.thisType
  let fn = gen.funcName
  var ma = gen.actualMinArgs
  result = newStmtList()
  if isva:
    result.add(quote do:
      if argc < `ma`:
        return JS_ThrowTypeError(ctx, "At least %d arguments required, " &
          "but only %d passed", `ma`, argc)
    )
  if gen.thisname.isSome:
    let tn = ident(gen.thisname.get)
    let ev = gen.errval
    result.add(quote do:
      if not (JS_IsUndefined(`tn`) or ctx.isGlobal(`tt`)) and not isInstanceOf(ctx, `tn`, `tt`):
        # undefined -> global.
        discard JS_ThrowTypeError(ctx, "'%s' called on an object that is not an instance of %s", `fn`, `tt`)
        return `ev`
    )

  if gen.funcName in js_errors:
    var tryWrap = newNimNode(nnkTryStmt)
    tryWrap.add(gen.jsCallAndRet)
    for error in js_errors[gen.funcName]:
      let ename = ident(error)
      var exceptBranch = newNimNode(nnkExceptBranch)
      let eid = ident("e")
      exceptBranch.add(newNimNode(nnkInfix).add(ident("as"), ename, eid))
      let throwName = ident("JS_Throw" & error.substr("JS_".len))
      exceptBranch.add(quote do:
        return `throwName`(ctx, "%s", cstring(`eid`.msg)))
      tryWrap.add(exceptBranch)
    gen.jsCallAndRet = tryWrap
  result.add(gen.jsCallAndRet)

proc newJSProc(gen: var JSFuncGenerator, params: openArray[NimNode], isva = true): NimNode =
  let jsBody = gen.newJSProcBody(isva)
  let jsPragmas = newNimNode(nnkPragma).add(ident("cdecl"))
  result = newProc(gen.newName, params, jsBody, pragmas = jsPragmas)
  gen.res = result

func getFuncName(fun: NimNode, jsname: string): string =
  if jsname != "":
    return jsname
  let x = $fun[0]
  if x == "$":
    # stringifier
    return "toString"
  return x

func getErrVal(t: BoundFunctionType): NimNode =
  if t in {PROPERTY_GET, PROPERTY_HAS}:
    return quote do: cint(-1)
  return quote do: JS_EXCEPTION

proc addJSContext(gen: var JSFuncGenerator) =
  if gen.funcParams.len > gen.i and
      gen.funcParams[gen.i].t.eqIdent(ident("JSContext")):
    gen.passCtx = true
    gen.jsFunCall.add(ident("ctx"))
    inc gen.i

proc addThisName(gen: var JSFuncGenerator, thisname: Option[string]) =
  if thisname.isSome:
    gen.thisType = $gen.funcParams[gen.i][1]
    gen.newName = ident($gen.t & "_" & gen.thisType & "_" & gen.funcName)
  else:
    let rt = gen.returnType.get
    if rt.kind == nnkRefTy:
      gen.thisType = rt[0].strVal
    else:
      if rt.kind == nnkBracketExpr:
        gen.thisType = rt[1].strVal
      else:
        gen.thisType = rt.strVal
    gen.newName = ident($gen.t & "_" & gen.funcName)

func getActualMinArgs(gen: var JSFuncGenerator): int =
  var ma = gen.minArgs
  if gen.thisname.isSome:
    dec ma
  if gen.passCtx:
    dec ma
  assert ma >= 0
  return ma

proc setupGenerator(fun: NimNode, t: BoundFunctionType,
    thisname = some("this"), jsname: string = ""): JSFuncGenerator =
  let jsFunCallList = newStmtList()
  let funcParams = getParams(fun)
  var gen = JSFuncGenerator(
    t: t,
    funcName: getFuncName(fun, jsname),
    generics: getGenerics(fun),
    funcParams: funcParams,
    returnType: getReturn(fun),
    minArgs: funcParams.getMinArgs(),
    original: fun,
    thisname: thisname,
    errval: getErrVal(t),
    dielabel: ident("ondie"),
    jsFunCallList: jsFunCallList,
    jsFunCallLists: @[jsFunCallList],
    jsFunCall: newCall(fun[0])
  )
  gen.addJSContext()
  gen.actualMinArgs = gen.getActualMinArgs() # must come after passctx is set
  gen.addThisName(thisname)
  return gen

proc makeJSCallAndRet(gen: var JSFuncGenerator, okstmt, errstmt: NimNode) =
  let jfcl = gen.jsFunCallList
  let dl = gen.dielabel
  gen.jsCallAndRet = if gen.returnType.issome:
    quote do:
      block `dl`:
        return ctx.toJS(`jfcl`)
      `errstmt`
  else:
    quote do:
      block `dl`:
        `jfcl`
        `okstmt`
      `errstmt`

macro jsctor*(fun: typed) =
  var gen = setupGenerator(fun, CONSTRUCTOR, thisname = none(string))
  if gen.newName.strVal in existing_funcs:
    #TODO TODO TODO implement function overloading
    error("Function overloading hasn't been implemented yet...")
  gen.addRequiredParams()
  gen.addOptionalParams()
  gen.finishFunCallList()
  let errstmt = quote do:
    return JS_ThrowTypeError(ctx, "Invalid parameters passed to constructor")
  # no okstmt
  gen.makeJSCallAndRet(nil, errstmt)
  discard gen.newJSProc(getJSParams())
  gen.registerConstructor()
  result = newStmtList(fun)

macro jshasprop*(fun: typed) =
  var gen = setupGenerator(fun, PROPERTY_HAS, thisname = some("obj"))
  if gen.newName.strVal in existing_funcs:
    #TODO TODO TODO ditto
    error("Function overloading hasn't been implemented yet...")
  gen.addFixParam("obj")
  gen.addFixParam("atom")
  gen.finishFunCallList()
  let jfcl = gen.jsFunCallList
  let dl = gen.dielabel
  gen.jsCallAndRet = quote do:
    block `dl`:
      let retv = `jfcl`
      return cint(retv)
    doAssert false # TODO?
  let jsProc = gen.newJSProc(getJSHasPropParams(), false)
  gen.registerFunction()
  result = newStmtList(fun, jsProc)

macro jsgetprop*(fun: typed) =
  var gen = setupGenerator(fun, PROPERTY_GET, thisname = some("obj"))
  if gen.newName.strVal in existing_funcs:
    #TODO TODO TODO ditto
    error("Function overloading hasn't been implemented yet...")
  gen.addFixParam("obj")
  gen.addFixParam("prop")
  gen.finishFunCallList()
  let jfcl = gen.jsFunCallList
  let dl = gen.dielabel
  gen.jsCallAndRet = quote do:
    block `dl`:
      let retv = ctx.toJS(`jfcl`)
      if retv != JS_NULL:
        desc[].setter = JS_UNDEFINED
        desc[].getter = JS_UNDEFINED
        desc[].value = retv
        desc[].flags = 0
        return cint(1)
    return cint(0)
  let jsProc = gen.newJSProc(getJSGetPropParams(), false)
  gen.registerFunction()
  result = newStmtList(fun, jsProc)

macro jsfgetn(jsname: static string, fun: typed) =
  var gen = setupGenerator(fun, GETTER, jsname = jsname)
  if gen.actualMinArgs != 0 or gen.funcParams.len != gen.minArgs:
    error("jsfget functions must only accept one parameter.")
  if gen.returnType.isnone:
    error("jsfget functions must have a return type.")
  if gen.newName.strVal in existing_funcs:
    #TODO TODO TODO ditto
    error("Function overloading hasn't been implemented yet...")
  gen.addFixParam("this")
  gen.finishFunCallList()
  gen.makeJSCallAndRet(nil, quote do: discard)
  let jsProc = gen.newJSProc(getJSGetterParams(), false)
  gen.registerFunction()
  result = newStmtList(fun, jsProc)

# "Why?" So the compiler doesn't cry.
macro jsfget*(fun: typed) =
  quote do:
    jsfgetn("", `fun`)

macro jsfget*(jsname: static string, fun: typed) =
  quote do:
    jsfgetn(`jsname`, `fun`)

# Ideally we could simulate JS setters using nim setters, but nim setters
# won't accept types that don't match their reflected field's type.
macro jsfsetn(jsname: static string, fun: typed) =
  var gen = setupGenerator(fun, SETTER, jsname = jsname)
  if gen.actualMinArgs != 1 or gen.funcParams.len != gen.minArgs:
    error("jsfset functions must accept two parameters")
  if gen.returnType.isSome:
    let rt = gen.returnType.get
    #TODO ??
    let rtType = rt[0]
    let errType = getTypeInst(Err)
    if not errType.sameType(rtType) and not rtType.sameType(errType):
      error("jsfset functions must not have a return type")
  gen.addFixParam("this")
  gen.addFixParam("val")
  gen.finishFunCallList()
  # return param anyway
  let okstmt = quote do: discard
  let errstmt = quote do: return JS_DupValue(ctx, val)
  gen.makeJSCallAndRet(okstmt, errstmt)
  let jsProc = gen.newJSProc(getJSSetterParams(), false)
  gen.registerFunction()
  result = newStmtList(fun, jsProc)

macro jsfset*(fun: typed) =
  quote do:
    jsfsetn("", `fun`)

macro jsfset*(jsname: static string, fun: typed) =
  quote do:
    jsfsetn(`jsname`, `fun`)

macro jsfuncn*(jsname: static string, fun: typed) =
  var gen = setupGenerator(fun, FUNCTION, jsname = jsname)
  if gen.minArgs == 0:
    error("Zero-parameter functions are not supported. (Maybe pass Window or Client?)")
  gen.addFixParam("this")
  gen.addRequiredParams()
  gen.addOptionalParams()
  gen.finishFunCallList()
  let okstmt = quote do:
    return JS_UNDEFINED
  let errstmt = quote do:
    return JS_ThrowTypeError(ctx, "Invalid parameters passed to function")
  gen.makeJSCallAndRet(okstmt, errstmt)
  let jsProc = gen.newJSProc(getJSParams())
  gen.registerFunction()
  result = newStmtList(fun, jsProc)

macro jsfunc*(fun: typed) =
  quote do:
    jsfuncn("", `fun`)

macro jsfunc*(jsname: static string, fun: typed) =
  quote do:
    jsfuncn(`jsname`, `fun`)

macro jsfin*(fun: typed) =
  var gen = setupGenerator(fun, FINALIZER, thisname = some("fin"))
  registerFunction(gen.thisType, FINALIZER, gen.funcName, gen.newName)
  fun

# Having the same names for these and the macros leads to weird bugs, so the
# macros get an additional f.
template jsget*() {.pragma.}
template jsget*(name: string) {.pragma.}
template jsset*() {.pragma.}
template jsset*(name: string) {.pragma.}
template jsgetset*() {.pragma.}
template jsgetset*(name: string) {.pragma.}

proc js_illegal_ctor*(ctx: JSContext, this: JSValue, argc: cint, argv: ptr JSValue): JSValue {.cdecl.} =
  return JS_ThrowTypeError(ctx, "Illegal constructor")

type
  JSObjectPragma = object
    name: string
    varsym: NimNode

  JSObjectPragmas = object
    jsget: seq[JSObjectPragma]
    jsset: seq[JSObjectPragma]
    jsinclude: seq[JSObjectPragma]

func getPragmaName(varPragma: NimNode): string =
  if varPragma.kind == nnkExprColonExpr:
    return $varPragma[0]
  return $varPragma

func getStringFromPragma(varPragma: NimNode): Option[string] =
  if varPragma.kind == nnkExprColonExpr:
    if not varPragma.len == 1 and varPragma[1].kind == nnkStrLit:
      error("Expected string as pragma argument")
    return some($varPragma[1])

proc findPragmas(t: NimNode): JSObjectPragmas =
  let typ = t.getTypeInst()[1] # The type, as declared.
  var impl = typ.getTypeImpl() # ref t
  assert impl.kind == nnkRefTy, "Only ref nodes are supported..."
  impl = impl[0].getImpl()
  # stolen from std's macros.customPragmaNode
  var identDefsStack = newSeq[NimNode](impl[2].len)
  for i in 0..<identDefsStack.len: identDefsStack[i] = impl[2][i]
  while identDefsStack.len > 0:
    var identDefs = identDefsStack.pop()
    case identDefs.kind
    of nnkRecList:
      for child in identDefs.children:
        identDefsStack.add(child)
    of nnkRecCase:
      # Add condition definition
      identDefsStack.add(identDefs[0])
      # Add branches
      for i in 1 ..< identDefs.len:
        identDefsStack.add(identDefs[i].last)
    else:
      for i in 0 .. identDefs.len - 3:
        let varNode = identDefs[i]
        if varNode.kind == nnkPragmaExpr:
          var varName = varNode[0]
          if varName.kind == nnkPostfix:
            # This is a public field. We are skipping the postfix *
            varName = varName[1]
          var varPragmas = varNode[1]
          for varPragma in varPragmas:
            let pragmaName = getPragmaName(varPragma)
            let op = JSObjectPragma(
              name: getStringFromPragma(varPragma).get($varName),
              varsym: varName
            )
            case pragmaName
            of "jsget": result.jsget.add(op)
            of "jsset": result.jsset.add(op)
            of "jsgetset":
              result.jsget.add(op)
              result.jsset.add(op)
            of "jsinclude": result.jsinclude.add(op)

proc nim_finalize_for_js*[T](obj: ptr T) =
  for rt in runtimes:
    let rtOpaque = rt.getOpaque()
    rtOpaque.plist.withValue(cast[pointer](obj), v):
      let p = v[]
      let val = JS_MKPTR(JS_TAG_OBJECT, p)
      let classid = JS_GetClassID(val)
      rtOpaque.fins.withValue(classid, fin):
        fin[](val)
      JS_SetOpaque(val, nil)
      rtOpaque.plist.del(cast[pointer](obj))
      JS_FreeValueRT(rt, val)

type
  TabGetSet* = object
    name*: string
    get*: JSGetterMagicFunction
    set*: JSSetterMagicFunction
    magic*: uint16

  TabFunc* = object
    name*: string
    fun*: JSCFunction

template jsDestructor*[U](T: typedesc[ref U]) =
  static:
    js_dtors.incl($T)
  proc `=destroy`(obj: var U) =
    nim_finalize_for_js(addr obj)

macro registerType*(ctx: typed, t: typed, parent: JSClassID = 0,
    asglobal = false, nointerface = false, name: static string = "",
    has_extra_getset: static bool = false,
    extra_getset: static openarray[TabGetSet] = [],
    namespace: JSValue = JS_NULL, errid = opt(JSErrorEnum)): JSClassID =
  result = newStmtList()
  let tname = t.strVal # the nim type's name.
  if tname notin js_dtors:
    warning("No destructor has been defined for type " & tname)
  let name = if name == "": tname else: name # possibly a different name, e.g. Buffer for Container
  var sctr = ident("js_illegal_ctor")
  # constructor
  var ctorFun: NimNode
  var ctorImpl: NimNode
  # custom finalizer
  var finName = newNilLit()
  var finFun = newNilLit()
  # generic property getter (e.g. attribute["id"])
  var propGetFun = newNilLit()
  var propHasFun = newNilLit()
  # property setters/getters declared on classes (with jsget, jsset)
  var setters, getters: Table[string, NimNode]
  let tabList = newNimNode(nnkBracket)
  let pragmas = findPragmas(t)
  for op in pragmas.jsget:
    let node = op.varsym
    let fn = op.name
    let id = ident($GETTER & "_" & tname & "_" & fn)
    result.add(quote do:
      proc `id`(ctx: JSContext, this: JSValue): JSValue {.cdecl.} =
        if not (JS_IsUndefined(this) or ctx.isGlobal(`tname`)) and not ctx.isInstanceOf(this, `tname`):
          # undefined -> global.
          return JS_ThrowTypeError(ctx, "'%s' called on an object that is not an instance of %s", `fn`, `name`)
        let arg_0 = fromJS_or_return(`t`, ctx, this)
        return toJS(ctx, arg_0.`node`)
    )
    registerFunction(tname, GETTER, fn, id)
  for op in pragmas.jsset:
    let node = op.varsym
    let fn = op.name
    let id = ident($SETTER & "_" & tname & "_" & fn)
    result.add(quote do:
      proc `id`(ctx: JSContext, this: JSValue, val: JSValue): JSValue {.cdecl.} =
        if not (JS_IsUndefined(this) or ctx.isGlobal(`tname`)) and not ctx.isInstanceOf(this, `tname`):
          # undefined -> global.
          return JS_ThrowTypeError(ctx, "'%s' called on an object that is not an instance of %s", `fn`, `name`)
        let arg_0 = fromJS_or_return(`t`, ctx, this)
        let arg_1 = val
        arg_0.`node` = fromJS_or_return(typeof(arg_0.`node`), ctx, arg_1)
        return JS_DupValue(ctx, arg_1)
    )
    registerFunction(tname, SETTER, fn, id)

  if tname in BoundFunctions:
    for fun in BoundFunctions[tname].mitems:
      var f0 = fun.name
      let f1 = fun.id
      if fun.name.endsWith("_exceptions"):
        fun.name = fun.name.substr(0, fun.name.high - "_exceptions".len)
      case fun.t
      of FUNCTION:
        f0 = fun.name
        tabList.add(quote do:
          JS_CFUNC_DEF(`f0`, 0, cast[JSCFunction](`f1`)))
      of CONSTRUCTOR:
        ctorImpl = js_funcs[$f0].res
        if ctorFun != nil:
          error("Class " & tname & " has 2+ constructors.")
        ctorFun = f1
      of GETTER:
        getters[f0] = f1
      of SETTER:
        setters[f0] = f1
      of PROPERTY_GET:
        propGetFun = f1
      of PROPERTY_HAS:
        propHasFun = f1
      of FINALIZER:
        f0 = fun.name
        finFun = ident(f0)
        finName = f1

  for k, v in getters:
    if k in setters:
      let s = setters[k]
      tabList.add(quote do: JS_CGETSET_DEF(`k`, `v`, `s`))
    else:
      tabList.add(quote do: JS_CGETSET_DEF(`k`, `v`, nil))
  for k, v in setters:
    if k notin getters:
      tabList.add(quote do: JS_CGETSET_DEF(`k`, nil, `v`))

  if has_extra_getset:
    #HACK: for some reason, extra_getset gets weird contents when nothing is
    # passed to it.
    for x in extra_getset:
      let k = x.name
      let g = x.get
      let s = x.set
      let m = x.magic
      tabList.add(quote do: JS_CGETSET_MAGIC_DEF(`k`, `g`, `s`, `m`))

  if ctorFun != nil:
    sctr = ctorFun
    result.add(ctorImpl)

  if finFun.kind != nnkNilLit:
    result.add(quote do:
      proc `finName`(val: JSValue) =
        let opaque = JS_GetOpaque(val, JS_GetClassID(val))
        if opaque != nil:
          `finFun`(cast[`t`](opaque))
    )

  let dfin = ident("js_" & tname & "ClassCheckDestroy")
  result.add(quote do:
    proc `dfin`(rt: JSRuntime, val: JSValue): JS_BOOL {.cdecl.} =
      let opaque = JS_GetOpaque(val, JS_GetClassID(val))
      if opaque != nil:
        # Before this function is called, the ownership model is
        # JSObject -> Nim object.
        # Here we change it to Nim object -> JSObject.
        # As a result, Nim object's reference count can now reach zero (it is
        # no longer "referenced" by the JS object).
        # nim_finalize_for_js will be invoked by the Nim GC when the Nim
        # refcount reaches zero. Then, the JS object's opaque will be set
        # to nil, and its refcount decreased again, so next time this function
        # will return true.
        GC_unref(cast[`t`](opaque))
        # Returning false from this function signals to the QJS GC that it
        # should not be collected yet. Accordingly, the JSObject's refcount
        # will be set to one again.
        return false
      return true
  )

  let endstmts = newStmtList()
  let cdname = "classDef" & name
  let classDef = ident("classDef")
  if propGetFun.kind != nnkNilLit or propHasFun.kind != nnkNilLit:
    endstmts.add(quote do:
      # No clue how to do this in pure nim.
      {.emit: ["""
static JSClassExoticMethods exotic = {
	.get_own_property = """, `propGetFun`, """,
	.has_property = """, `propHasFun`, """
};
static JSClassDef """, `cdname`, """ = {
	""", "\"", `name`, "\"", """,
        .can_destroy = """, `dfin`, """,
	.exotic = &exotic
};"""
      ].}
      var `classDef`: JSClassDefConst
      {.emit: [
        `classDef`, " = &", `cdname`, ";"
      ].}
    )
  else:
    endstmts.add(quote do:
      const cd = JSClassDef(
        class_name: `name`,
        can_destroy: `dfin`
      )
      let `classDef` = JSClassDefConst(unsafeAddr cd))

  endStmts.add(quote do:
    var x: `t`
    new(x)
    `ctx`.newJSClass(`classDef`, `tname`, `sctr`, `tabList`, getTypePtr(x),
      `parent`, `asglobal`, `nointerface`, `finName`, `namespace`, `errid`)
  )
  result.add(newBlockStmt(endstmts))

proc getMemoryUsage*(rt: JSRuntime): string =
  var m: JSMemoryUsage
  JS_ComputeMemoryUsage(rt, addr m)
  result = fmt"""
memory allocated: {m.malloc_count} {m.malloc_size} ({float(m.malloc_size)/float(m.malloc_count):.1f}/block)
memory used: {m.memory_used_count} {m.memory_used_size} ({float(m.malloc_size-m.memory_used_size)/float(m.memory_used_count):.1f} average slack)
atoms: {m.atom_count} {m.atom_size} ({float(m.atom_size)/float(m.atom_count):.1f}/atom)
strings: {m.str_count} {m.str_size} ({float(m.str_size)/float(m.str_count):.1f}/string)
objects: {m.obj_count} {m.obj_size} ({float(m.obj_size)/float(m.obj_count):.1f}/object)
properties: {m.prop_count} {m.prop_size} ({float(m.prop_size)/float(m.obj_count):.1f}/object)
shapes: {m.shape_count} {m.shape_size} ({float(m.shape_size)/float(m.shape_count):.1f}/shape)
js functions: {m.js_func_count} {m.js_func_size} ({float(m.js_func_size)/float(m.js_func_count):.1f}/function)
native functions: {m.c_func_count}
arrays: {m.array_count}
fast arrays: {m.fast_array_count}
fast array elements: {m.fast_array_elements} {m.fast_array_elements*sizeof(JSValue)} ({float(m.fast_array_elements)/float(m.fast_array_count):.1f})
binary objects: {m.binary_object_count} {m.binary_object_size}"""

proc eval*(ctx: JSContext, s: string, file: string, eval_flags: int): JSValue =
  return JS_Eval(ctx, cstring(s), cint(s.len), cstring(file), cint(eval_flags))

proc compileModule*(ctx: JSContext, s: string, file: cstring): JSValue =
  return JS_Eval(ctx, cstring(s), cint(s.len), file,
    cint(JS_EVAL_TYPE_MODULE or JS_EVAL_FLAG_COMPILE_ONLY))
