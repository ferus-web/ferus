import std/[streams]
import components/web/dom
import pretty

let strm = newStringStream("""
<!DOCTYPE html>
<html>
  <head>
    <title>Hello Ferus!</title>
  </head>
  <body>
    <p>Hello Ferus!</p>
    <img src="hehehehaw.jpg"></img>
  </body>
</html>
""")

let document = parseHtml(strm)

for elem in document.elementNodes:
  print elem.tagType()

  for child in elem.elementNodes:
    print child.tagType()

    if child.tagType() == TAG_BODY:
      for items in child.elementNodes:
        print items.tagType()

        if items.tagType() == TAG_IMG:
          for x in items.attrs:
            let (prefix, namespace, name, value) = x

            print namespace
            print document.factory.atomToStr(name)
            print value

        for text in items.children:
          if text of Text:
            print Text(text).data
