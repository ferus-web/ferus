import pixie

type
  RenderPrimitive* = ref object of RootObj
    content*: string
    font*: Font
    dimensions*: tuple[w, h: float32]
    pos*: tuple[x, y: float32]
    img*: Image
    blurEnabled*: bool

  RenderImage* = ref object of RenderPrimitive

  RenderText* = ref object of RenderPrimitive

proc newRenderImage*(img: Image): RenderImage =
  RenderImage(img: img)

proc newRenderText*(text: string, font: Font, dimensions: tuple[w, h: float32],
                    pos: tuple[x, y: float32]): RenderText =
  RenderText(content: text, font: font, dimensions: dimensions, pos: pos)
