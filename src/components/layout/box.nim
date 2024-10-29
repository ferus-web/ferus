## Layout box
## Copyright (C) 2024 Trayambak Rai and Ferus authors
import vmath, pixie

type
  BoxKind* {.pure.} = enum
    Block
    Inline

  Box* = ref object of RootObj
    pos*: Vec2
    width*, height*: int
    visible*: bool = true

    kind*: BoxKind

  TextBox* = ref object of Box
    text*: string
    fontSize*: float32

  ImageBox* = ref object of Box
    image*: Image # TODO: add streamed image loading
    content*: string
