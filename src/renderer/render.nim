import ferusgfx, windy, chronicles, opengl

type
  Renderer* = ref object of RootObj
    window*: Window
    sceneIdx*: int
    scenes*: seq[Scene]

proc render*(renderer: Renderer) =
  if renderer.scenes.len < 1:
    # There's nothing to render.
    pollEvents()
    return

  let current = renderer.scenes[renderer.sceneIdx]

  current.draw()
  pollEvents()

proc newRenderer*(
  width, height: int32
): Renderer =
  Renderer(
    window: newWindow("Ferus", ivec2(width, height)),
    sceneIdx: 0,
    scenes: @[]
  )
