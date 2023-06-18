#[
 DOM parser, turns HTMLElement(s) into LayoutElement(s)
]#
import ../../dom/dom, 
       ../label,
       ../breakline,
       ../element,
      ../../renderer/[primitives, render, fontmanager],
      ferushtml

proc parseDOM*(dom: DOM, renderer: Renderer, fontMgr: FontManager, layoutTree: var seq[LayoutElement]) =
 for child in dom.document.root.findChildByTag("html").findChildByTag("body").children:
  echo child.tag
  if child.tag == "p":
   layoutTree.add(
    newLabel(
     child.textContent, renderer, fontMgr
    )
   )
  elif child.tag == "br":
   layoutTree.add(
    newBreakline(renderer)
   )