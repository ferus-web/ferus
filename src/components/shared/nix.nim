## Shared *NIX utilities

var FIONREAD* {.importc, header: "<sys/ioctl.h>".}: cint
proc ioctl*(
  fd: cint, op: cint, argp: pointer
): cint {.importc, header: "<sys/ioctl.h>".}
