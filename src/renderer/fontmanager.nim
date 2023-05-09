import pixie, std/tables, chronicles


type FontManager* = ref object of RootObj
  fonts*: TableRef[string, Font]

proc loadFont*(fontMgr: FontManager, fontName, fontPath: string): Font =
  if fontName in fontMgr.fonts:
    warn "[src/renderer/fontmanager.nim] Attempting to override already existing font."
  fontMgr.fonts[fontName] = readFont(fontPath)

  return fontMgr.fonts[fontName]

proc getFont*(fontMgr: FontManager, fontName: string): Font =
  if fontName in fontMgr.fonts:
    return fontMgr.fonts[fontName]

  error "[src/renderer/fontmanager.nim] No such font exists! (or it is not loaded yet)", fName=fontName
  raise newException(ValueError, "No such font " & fontName & " exists in FontManager table")

proc newFontManager*: FontManager =
  FontManager(fonts: newTable[string, Font]())
