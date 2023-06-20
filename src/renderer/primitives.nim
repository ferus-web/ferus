import pixie

type
  PrimitiveType* = enum
    ptImg,
    ptText

  RenderPrimitive* = ref object of RootObj
    # A string containing text content if this is a RenderText, else a nil pointer
    content*: string

    # A font for a text label if this is a RenderText, else a nil pointer
    font*: Font

    # Position (x-coordinate, y-coordinate)
    pos*: tuple[x, y: float32]

    # Pixie Image for a RenderImage, else a nil pointer
    img*: Image

    # Is blur enabled for a RenderImage, else a nil pointer
    blurEnabled*: bool
    
    # Dimensions
    dimensions*: tuple[w, h: float32]

    # What render primitive this is since they all derive from the same class
    pType*: PrimitiveType

    sizeInc*: int

  RenderImage* = ref object of RenderPrimitive

  RenderText* = ref object of RenderPrimitive

proc newRenderImage*(img: Image, dimensions: tuple[w, h: float32]): RenderImage =
  result = RenderImage(
    pos: (x: 0f, y: 0f), img: img, blurEnabled: false, 
    pType: ptImg, dimensions: dimensions
  )

proc clear*(renderImage: RenderImage, clearColor: SomeColor = (r: 255, g: 255, b: 255, a: 255)) =
  renderImage.img.fill(clearColor)

proc newRenderText*(text: string, font: Font, dimensions: tuple[w, h: float32],
                    pos: tuple[x, y: float32], sizeInc: int = 0): RenderText =
  RenderText(content: text, font: font, dimensions: dimensions, pos: pos, pType: ptText, sizeInc: sizeInc)