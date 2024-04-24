import ferusgfx, ferus_ipc/shared, vmath

type
  IPCDrawable* = ref object of RootObj
  # FIXME: perhaps move this into `src/ferusgfx/sandboxed`

  TextNode* = ref object of IPCDrawable
    content*: string
    position*: Vec2
    font*: string ## this isnt the path!

  ImageNode* = ref object of IPCDrawable
    path*: string
    position*: Vec2

  IPCDisplayList* = GDisplayList

  RendererMutationPacket* = ref object
    kind: FerusMagic = feRendererMutation
    list*: IPCDisplayList

  RendererLoadFontPacket* = ref object
    kind: FerusMagic = feRendererLoadFont
    content*: string
