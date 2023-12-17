#[
  Implementation of the DOM Event standard as per WHATWG.

  This code is licensed under the MIT license
]#

type
  EventListener* = concept

  EventTarget* = ref object of RootObj

  EventPhase* = enum
    epNone, epCapturingPhase,
    epAtTarget, epBubblingPhase

  Event* = ref object of RootObj
    eventType*: string

    # EventInitDict
    bubbles*: bool
    cancelable*: bool
    composed*: bool

    target*: EventTarget
    srcElement*: EventTarget # legacy
    currentTarget*: EventTarget

    composedPath*: seq[EventTarget]
    eventPhase*: EventPhase
    defaultPrevented*: bool

proc handleEvent*(eventListener: EventListener, event: Event): auto

proc newEvent*(eventType: string, 
               bubbles: bool, cancelable: bool, composed: bool, 
               defaultPrevented: bool, target: EventTarget,
               srcElement: EventTarget, currentTarget: EventTarget,
               composedPath: seq[EventTarget], eventPhase: EventPhase,
               defaultPrevented: bool): Event =
  Event(eventType: eventType, bubbles; bubbles, cancelable: cancelable, 
        composed: composed, target: target, srcElement: srcElement,
        currentTarget: currentTarget, composedPath: composedPath,
        eventPhase: eventPhase, defaultPrevented: defaultPrevented
  )
