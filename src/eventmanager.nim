type Event* = ref object of RootObj
  name*: string
  listeners*: seq[proc(name: string) {.closure.}]

proc trigger*(event: Event) =
  for listeningFn in event.listeners:
    listeningFn(event.name)

proc subscribe*(event: Event, fn: proc) =
  event.listeners.add(fn)

proc newEvent*(name: string): Event =
  Event(name: name, listeners: @[])

type EventManager* = ref object of RootObj
  events*: seq[Event]

proc createEvent*(eventMgr: EventManager, name: string): Event =
  var event = newEvent(name)
  eventMgr.events.add(event)
  return event

proc getEventByName*(eventManager: EventManager, name: string): Event =
  for event in eventManager.events:
    if event.name == name:
      return event

  # Since we are entitled to return an event any ways...
  eventManager.createEvent(name)

proc listenTo*(eventManager: EventManager, name: string, fn: proc) =
  var event: Event = eventManager.getEventByName(name: name)
  event.subscribe(fn)

proc trigger*(eventManager: EventManager, name: string) =
  var event = eventManager.getEventByName(name)
  event.trigger()

proc newEventManager*(): EventManager =
  EventManager(events: @[])
