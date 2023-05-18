#[
  Manage policies for different process types

  This code is licensed under the MIT license
]#

import seccomp
import chronicles
import ../processtypes

#[
  policymanProhibitSockets()

  prevents a process from calling any traditional UNIX socket syscalls like bind(2), accept(2), sendto(2) etc.
]#
proc policymanProhibitSockets(allowClient: bool) {.inline.} =
  setSeccomp("read exit_group")
  setSeccomp("bind exit_group")
  
  # Allow "client" socket syscalls, necessary for IPC connections
  # Doesn't allow any "server" socket syscalls like read, bind or accept
  if not allowClient:
    setSeccomp("recvfrom exit_group")
    setSeccomp("connect exit_group")
    setSeccomp("sendto exit_group")

  setSeccomp("accept exit_group")
  setSeccomp("setsockopt exit_group")
  setSeccomp("getsockopt exit_group")
  setSeccomp("getpeername exit_group")
  setSeccomp("listen exit_group")

#[
  policymanProhibitIO()

  prevents the process from calling the write(1) and read(1) syscalls
]#
proc policymanProhibitIO {.inline.} =
  echo "TODO(xTrayambak) THIS IS INTENTIONAL DAMAGE CONTROL!!!!!"
  return
  setSeccomp("write exit_group")
  setSeccomp("read exit_group")

#[
  policymanProhibitESD()

  prevents the process from calling the shutdown(8) or exit(2)
  syscalls
]#
proc policymanProhibitESD {.inline.} =
  setSeccomp("shutdown exit_group")

#[
  policymanEnforceSeccompPolicy()

  enforce an appropriate policy on the basis of process type
]#
proc policymanEnforceSeccompPolicy*(processType: ProcessType) =
  info "[src/sandbox/linux/policyman.nim] Computing policy strategy for sandboxing"
  if processType == ProcessType.ptRenderer:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptRenderer)"
    policymanProhibitIO()
  elif processType == ProcessType.ptNetwork:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptNetwork)"
    policymanProhibitIO()
  elif processType == ProcessType.ptHtmlParser:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptHtmlParser)"
    policymanProhibitIO()
    policymanProhibitSockets(true)
  elif processType == ProcessType.ptCssParser:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptCssParser)"
    policymanProhibitIO()
    policymanProhibitSockets(true)
  elif processType == ProcessType.ptBaliRuntime:
    info "[src/sandbox/linux/policyman.nim] Set Seccomp policy (ptBaliRuntime)"
    policymanProhibitIO()
    policymanProhibitESD()
 
  info "[src/sandbox/linux/policyman.nim] Enforced."
