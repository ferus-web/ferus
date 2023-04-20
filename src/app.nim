import eventmanager
import ui

import chronicles

type Application* = ref object of RootObj
  eventManager*: EventManager
  uiManager*: UIManager

proc init*(application: Application) =
  info "Initializing UIManager"
  application.uiManager.init()

proc newApplication*(): Application =
  var eventMgr = newEventManager()
  var uiMgr = newUIManager(eventMgr)
  Application(eventManager: eventMgr, uiManager: uiMgr)
