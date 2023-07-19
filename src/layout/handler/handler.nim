#[
 DOM parser, turns HTMLElement(s) into LayoutNode(s)

 This code is licensed under the MIT license

 Authors: xTrayambak (xtrayambak at gmail dot com)
]#
import ../../dom/dom, 
       ../label,
       ../node,
       #../breakline,
       #../element,
       #../image,
      ../../renderer/[primitives, render, fontmanager],
      std/strutils,
      cssgrid,
      pixie,
      ferushtml

proc parseDOM*(dom: DOM, renderer: Renderer, fontMgr: FontManager, layoutTree: var seq[LayoutNode], parent: GridNode) =
 for child in dom.document.root.findChildByTag("html").findChildByTag("body").children:
  if child.tag == "p":
   layoutTree.add(
    newLabel(
     child.textContent, parent, 
     fontMgr.getFontPath("Default")
    )
   )
  #[elif child.tag == "br":
   layoutTree.add(
    newBreakline(renderer)
   )
  elif child.tag.startsWith("h"):
   # TODO(xTrayambak): add support for h1, h2, h3, etc.
   layoutTree.add(
    newLabel(
     child.textContent, renderer, fontMgr, 256
    )
   )
  elif child.tag == "img":
    layoutTree.add(
     newLayoutImage(
      readImage(
       child.getAttrByName("src").value.payload
      ),
      renderer
     )
    )]#