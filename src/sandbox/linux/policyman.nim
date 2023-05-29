#[
  Manage policies for different process types

  This code is licensed under the MIT license
]#

import firejail
import chronicles
import ../processtypes

proc policymanCreateAppropriateJail*(procType: ProcessType): Firejail =
  info "[src/sandbox/linux/policyman.nim] Creating jail"

  if procType == ptRenderer:
    return Firejail(no3d: false, # Hardware acceleration
             noDbus: true, 
             noDvd: true, 
             noRoot: true, 
             noSound: false, # Sound playback
             noVideo: false, # GStreamer
             noShell: true,
             noX: false, # X11 (bleh)
             noNet: false, # IPC client
             noIp: true,
             writables: false
    )
  elif procType == ptNetwork:
    return Firejail(no3d: true,
             noDbus: true,
             noDvd: true,
             noRoot: true,
             noSound: true,
             noVideo: true,
             noShell: true,
             noX: true,
             noNet: false, # Sockets/IPC
             noIp: false,   # Sockets/IPC
             writables: false
    )
  elif procType == ptHtmlParser or procType == ptCssParser:
    return Firejail(no3d: true,
             noDbus: true,
             noDvd: true,
             noRoot: true,
             noSound: true,
             noVideo: true,
             noShell: true,
             noX: true,
             noNet: false, # IPC
             noIp: true,
             writables: false
    )
  elif procType == ptBaliRuntime:
    return Firejail(no3d: true,
             noDbus: true,
             noDvd: true,
             noRoot: true,
             noSound: true,
             noVideo: true,
             noShell: true,
             noX: true,
             noNet: false,
             noIp: false,
             writables: false
    )
