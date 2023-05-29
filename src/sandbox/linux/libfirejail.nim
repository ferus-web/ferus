import osproc, taskpools, chronicles

var tp = Taskpool.new()
const FIREJAIL_DEFAULT_PARAMS = " --noroot --disable-mnt --seccomp --apparmor --nodbus"

type Permissions* = enum
  gfx, x11

proc spawnProc*(args: string, permissionsDeny: seq[Permissions]) =
  var fjCmd = FIREJAIL_DEFAULT_PARAMS & " "

  for perm in permissionsDeny:
    if perm == gfx:
      fjCmd = fjCmd & "--no3d "
    elif perm == x11:
      fjCmd = fjcmd & "--noX "

  discard tp.spawn execCmd("firejail " & args)
