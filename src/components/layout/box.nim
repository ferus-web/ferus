## Layout box
## Copyright (C) 2024 Trayambak Rai and Ferus authors
import vmath, pixie

type
  Box* = ref object of RootObj
    pos*: Vec2
    width*, height*: int
    visible*: bool = true

  TextBox* = ref object of Box
    text*: string
    fontSize*: float32

  ImageBox* = ref object of Box
    image*: Image # FIXME: add streamed image loading
    content*: string
