#[
  Manage policies for different process types

  This code is licensed under the MIT license
]#

import seccomp
import seccomp/seccomp_lowlevel
import chronicles
import ../processtypes

#[
  policymanProhibitSockets()

  prevents a process from calling any traditional UNIX socket syscalls like bind(2), accept(2), sendto(2) etc.
]#
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

#[
  policymanProhibitIO()

  prevents the process from calling the write(1) and read(1) syscalls
]#
proc policymanProhibitIO(ctx: ScmpFilterCtx) {.inline.} =
  ctx.add_rule(Kill, "write")
  ctx.add_rule(Kill, "read")

#[
  policymanProhibitESD()

  prevents the process from calling the shutdown(8) or exit(2)
  syscalls
]#
proc policymanProhibitESD(ctx: ScmpFilterCtx) {.inline.} =
  ctx.add_rule(Kill, "shutdown")
  ctx.add_rule(Kill, "exit")

#[
  policymanEnforceSeccompPolicy()

  enforce an appropriate policy on the basis of process type
]#
proc policymanEnforceSeccompPolicy*(ctx: ScmpFilterCtx, processType: ProcessType) =
  info "[src/sandbox/linux/policyman.nim] Computing policy strategy for sandboxing"
  if processType == ProcessType.ptRenderer:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptRenderer)"
    policymanProhibitIO(ctx)
  elif processType == ProcessType.ptNetwork:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptNetwork)"
    policymanProhibitIO(ctx)
  elif processType == ProcessType.ptHtmlParser:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptHtmlParser)"
    policymanProhibitIO(ctx)
    policymanProhibitSockets(ctx)
  elif processType == ProcessType.ptCssParser:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptCssParser)"
    policymanProhibitIO(ctx)
    policymanProhibitSockets(ctx)
  elif processType == ProcessType.ptBaliRuntime:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptBaliRuntime)"
    policymanProhibitIO(ctx)
    policymanProhibitESD(ctx)
 
  info "[src/sandbox/linux/policyman.nim] Enforcing Seccomp policies! This process will no longer be able to do certain things."
  ctx.load()
