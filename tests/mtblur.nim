import ../src/renderer/effects, pixie

var img = newImage(400, 400)
img.fill(rgba(231, 212, 241, 255))

img.blurImg(2)

img.writeFile("mtblur.png")
