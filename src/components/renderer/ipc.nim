import ferusgfx, ferus_ipc/shared, vmath

type
  TextNode* = ref object
    content*: string
    position*: Vec2
    font*: string ## this isnt the path!

  ImageNode* = ref object
    path*: string
    position*: Vec2

  RendererMutationPacket*[T] = ref object
    kind: FerusMagic = feRendererMutation
    dkind*: uint

    add*, remove*: T

  RendererLoadFontPacket* = ref object
    kind: FerusMagic = feRendererLoadFont
    name*, content*, format*: string
  
  RendererSetWindowTitle* = ref object
    kind: FerusMagic = feRendererSetWindowTitle
    title*: string
