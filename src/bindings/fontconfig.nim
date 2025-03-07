## fontconfig bindings
## Author:
## Trayambak Rai (xtrayambak at disroot dot org)

import std/strutils

{.passC: gorge("pkg-config --cflags fontconfig").strip().}
{.passL: gorge("pkg-config --libs fontconfig").strip().}

{.push header: "<fontconfig.h>", importc.}

var
  FC_MAJOR*: cint
  FC_MINOR*: cint
  FC_REVISION*: cint
  
  FcFalse*: cint
  FcTrue*: cint
  FcDontCare*: cint

template def(nam: untyped) =
  var `nam`*: cstring

def FC_FAMILY
def FC_STYLE
def FC_SLANT
def FC_WEIGHT
def FC_SIZE
def FC_ASPECT
def FC_PIXEL_SIZE
def FC_SPACING
def FC_FOUNDRY
def FC_ANTIALIAS
def FC_HINTING
def FC_HINT_STYLE
def FC_VERTICAL_LAYOUT
def FC_AUTOHINT
def FC_GLOBAL_ADVANCE
def FC_WIDTH
def FC_FILE
def FC_INDEX
def FC_FT_FACE
def FC_RASTERIZER
def FC_OUTLINE
def FC_SCALABLE
def FC_COLOR
def FC_VARIABLE
def FC_SCALE
def FC_SYMBOL
def FC_DPI
def FC_RGBA
def FC_MINSPACE
def FC_SOURCE
def FC_CHARSET
def FC_LANG
def FC_FONTVERSION
def FC_FULLNAME
def FC_FAMILYLANG
def FC_STYLELANG
def FC_FULLNAMELANG
def FC_CAPABILITY
def FC_FONTFORMAT
def FC_EMBOLDEN
def FC_EMBEDDED_BITMAP
def FC_DECORATIVE
def FC_LCD_FILTER
def FC_FONT_FEATURES
def FC_FONT_VARIATIONS
def FC_NAMELANG
def FC_PRGNAME
def FC_HASH
def FC_POSTSCRIPT_NAME
def FC_FONT_HAS_HINT
def FC_ORDER
def FC_DESKTOP_NAME
def FC_NAMED_INSTANCE
def FC_FONT_WRAPPER
def FC_CACHE_SUFFIX
def FC_DIR_CACHE_FILE
def FC_USER_CACHE_FILE
def FC_CHARWIDTH
def FC_CHAR_HEIGHT
def FC_MATRIX
def FC_WEIGHT_THIN
def FC_WEIGHT_EXTRALIGHT
def FC_WEIGHT_ULTRALIGHT
def FC_WEIGHT_LEIGHT
def FC_WEIGHT_DEMILIGHT
def FC_WEIGHT_SEMILIGHT
def FC_WEIGHT_BOOK
def FC_WEIGHT_REGULAR
def FC_WEIGHT_NORMAL
def FC_WEIGHT_MEDIUM
def FC_WEIGHT_DEMIBOLD
def FC_WEIGHT_SEMIBOLD
def FC_WEIGHT_BOLD
def FC_WEIGHT_EXTRABOLD
def FC_WEIGHT_ULTRABOLD
def FC_WEIGHT_BLACK
def FC_WEIGHT_HEAVY
def FC_WEIGHT_EXTRABLACK
def FC_WEIGHT_ULTRABLACK
def FC_SLANT_ROMAN
def FC_SLANT_ITALIC
def FC_SLANT_OBLIQUE
def FC_WIDTH_ULTRACONDENSED
def FC_WIDTH_EXTRACONDENSED
def FC_WIDTH_CONDENSED
def FC_WIDTH_SEMICONDENSED
def FC_WIDTH_NORMAL
def FC_WIDTH_SEMIEXPANDED
def FC_WIDTH_EXPANDED
def FC_WIDTH_EXTRAEXPANDED
def FC_WIDTH_ULTRAEXPANDED
def FC_PROPORTIONAL
def FC_DUAL
def FC_MONO
def FC_CHARCELL
def FC_RGBA_UNKNOWN
def FC_RGBA_RGB
def FC_RGBA_BGR
def FC_RGBA_VRGB
def FC_RGBA_VBGR
def FC_RGBA_NONE
def FC_HINT_NONE
def FC_HINT_SLIGHT
def FC_HINT_MEDIUM
def FC_HINT_FULL
def FC_LCD_NONE
def FC_LCD_DEFAULT
def FC_LCD_LIGHT
def FC_LCD_LEGACY

type
  FcBool* = enum
    False = FcFalse
    True = FcTrue
    DontCare = FcDontCare

  FcType* {.pure.} = enum
    Unknown = -1
    Void
    Integer
    Double
    String
    Bool
    Matrix
    CharSet
    FTFace
    LangSet
    Range

  FcMatrixT* = object
    xx*, xy*, yx*, yy*: float32

  FcCharSetT* = object
  FcObjectType* = object
    object*: ptr uint8
    `type`*: FcType

  FcConstant* = object
    name*: cstring
    `object`*: ptr uint8
    value*: int32

  FcResult* {.pure.} = enum
    Match
    NoMatch
    TypeMismatch
    NoId
    OutOfMemory

  FcValueBinding* {.pure.} = enum
    Weak
    Strong
    Same
    End = int32.high

  FcPattern* = object

  FcPatternIter* = object
    dummy1*, dummy2*: pointer

  FcLangSet* = object
  FcRange* = object

  FcValueUnion {.union.} = object
    s*: cstring
    i*: int32
    b*: FcBool
    d*: float32
    m*: ptr FcMatrixT
    c*: ptr FcCharSetT
    f*: pointer
    l*: FcLangSet
    r*: FcRange

  FcValue* = object
    `type`*: FcType
    u*: FcValueUnion

  FcFontSet* = object
    nfont*, sfont*: int32
    fonts*: ptr ptr FcPattern

  FcObjectSet* = object
    nobject*, sobject*: int32
    objects*: ptr ptr uint8

  FcMatchKind* {.pure.} = enum
    Pattern
    Font
    Scan
    KindEnd

  FcLangResult* {.pure.} = enum
    Equal = 0
    DifferentCountry = 1
    DifferentLNG = 2

  FcSetName* {.pure.} = enum
    System = 0
    Application = 1

  FcConfigFileInfoIter* = object
    dummy1*, dummy2*, dummy3*: pointer

  FcAtomic* = object

  FcEndian* {.pure.} = enum
    Big
    Little

  FcConfig* = object
  FcFileCache* = object
  FcBlanks* = object
  FcStrList* = object
  FcStrSet* = object
  FcCache* = object

proc FcInit(): FcBool
proc FcBlanksCreate*: ptr FcBlanks
proc FcBlanksDestroy*(b: ptr FcBlanks)
proc FcGetLangs*: ptr FcStrSet
proc FcLangNormalize*: ptr cstring
proc FcLangGetCharSet*: ptr FcCharSet
proc FcLangSetCreate*: ptr FcLangSet
proc FcLangSetDestroy*(ls: ptr FcLangSet)
proc FcLangSetCopy*(ls: ptr FcLangSet): ptr FcLangSet
proc FcLangSetAdd*(ls: ptr FcLangSet, lang: cstring): FcBool
proc FcLangSetDel*(ls: ptr FcLangSet, lang: cstring): FcBool
proc FcLangSetHasLang*(ls: ptr FcLangSet, lang: cstring): FcLangResult
proc FcLangSetCompare*(lsa: ptr FcLangSet, lsb: ptr FcLangSet): FcLangResult
proc FcLangSetContains*(lsa: ptr FcLangSet, lsb: ptr FcLangSet): FcBool
proc FcLangSetGetLangs*(ls: ptr FcLangSet): ptr FcStrSet

{.pop.}

func newFcMatrix*: FcMatrixT =
  FcMatrixT(xx: 1, yy: 1, xy: 0, yx: 0)
