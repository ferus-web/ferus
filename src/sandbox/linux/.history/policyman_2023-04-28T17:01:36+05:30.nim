#[
  Manage policies for different process types
  
  This code is licensed under the MIT license
]#

import seccomp
import seccomp/seccomp_lowlevel
import chronicles
import ../processtypes

proc policymanEnforceSeccompPolicy*(ctx: ScmpFilterCtx, processType: ProcessType) =
  info "[src/sandbox/linux/policyman.nim] Computing policy strategy for sandboxing"
  if processType == ProcessType.ptNetwork:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy to write=KILL, read=KILL (ptNetwork)"
    ctx.add_rule(Kill, "write")
    ctx.add_rule(Kill, "read")
    ctx.add_rule(Kill, "bind")
    ctx.add_rule(Kill, "recvfrom")
    ctx.add_rule(Kill, "connect")

  info "[src/sandbox/linux/policyman.nim] Enforcing Seccomp policies! This process will no longer be able to do certain things."
  ctx.load()
