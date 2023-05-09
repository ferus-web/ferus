#[
  The sandbox utility for Ferus.

  This code is licensed under the MIT license
]#

import seccomp,
       seccomp/seccomp_lowlevel,
       chronicles,
       ../../ipc/client,
       ../processtypes,
       policyman

type
  FerusSandbox* = ref object of RootObj
    seccompCtx*: ScmpFilterCtx
    processType*: ProcessType

proc beginSandbox*(ferusSandbox: FerusSandbox) =
  info "[src/sandbox/linux/sandbox.nim] Sandbox is now being started!", backend="seccomp", seccompVersion=get_version()
  policymanEnforceSeccompPolicy(
    ferusSandbox.seccompCtx, 
    ferusSandbox.processType
  )
  info "[src/sandbox/linux/sandbox.nim] Sandbox completed! This process is now isolated.", backend="seccomp", seccompVersion=get_version()

proc newFerusSandbox*(parentPort: int, processType: ProcessType): FerusSandbox =
  info "[src/sandbox/linux/sandbox.nim] New sandbox initialized!"

  FerusSandbox(seccompCtx: seccomp_ctx(), processType: processType)
