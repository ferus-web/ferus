#[
  Manage policies for different process types
  
  This code is licensed under the MIT license
]#

import seccomp
import seccomp/seccomp_lowlevel
import chronicles
import ../processtypes

proc policymanProhibitSockets(ctx: ScmpFilterCtx) {.inline.} =
  ctx.add_rule(Kill, "read")
  ctx.add_rule(Kill, "bind")
  ctx.add_rule(Kill, "recvfrom")
  ctx.add_rule(Kill, "connect")
  ctx.add_rule(Kill, "accept")
  ctx.add_rule(Kill, "sendto")
  ctx.add_rule(Kill, "setsockopt")
  ctx.add_rule(Kill, "getsockopt")
  ctx.add_rule(Kill, "getpeername")
  ctx.add_rule(Kill, "listen")

proc policymanProhibitIO(ctx: ScmpFilterCtx) {.inline.} =
  ctx.add_rule(Kill, "write")
  ctx.add_rule(Kill, "read")

#[
  policymanProhibitESD()

  prevents the process from calling the shutdown(8) or 
]#
proc policymanProhibitESD(ctx: ScmpFilterCtx) {.inline.} =
  ctx.add_rule(Kill, "shutdown")
  ctx.add_rule(Kill, "exit")

proc policymanEnforceSeccompPolicy*(ctx: ScmpFilterCtx, processType: ProcessType) =
  info "[src/sandbox/linux/policyman.nim] Computing policy strategy for sandboxing"
  if processType == ProcessType.ptRenderer:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptRenderer)"
    ctx.add_rule(Kill, "write")
    ctx.add_rule(Kill, "read")
  elif processType == ProcessType.ptNetwork:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptNetwork)"
    ctx.add_rule(Kill, "write")
    ctx.add_rule(Kill, "read")
  elif processType == ProcessType.ptHtmlParser:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptHtmlParser)"
    ctx.add_rule(Kill, "write")
    ctx.add_rule(Kill, "read")
    policymanProhibitSockets()
 
  info "[src/sandbox/linux/policyman.nim] Enforcing Seccomp policies! This process will no longer be able to do certain things."
  ctx.load()
