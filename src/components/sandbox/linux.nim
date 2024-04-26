import std/logging, seccomp

const FORBIDDEN_SYSCALLS* = [
  # Deny I/O
  #"read", 
  "write", # <----- logging crashes without this
  "alarm",

  # Don't allow the process to start a TCP server
  "bind",
  "listen",

  # misc
  "kill",
  "getcwd",
  "link",
  "readlink",
  "symlink",
  "chown",
  "sysinfo",
  "setgid",
  "getgid",
  "ptrace",
  "reboot",
  "sethostname",
  "init_module",
  "splice",
  "migrate_pages",
  "kexec_load",
  "shutdown",
]

const ALLOWED_SYSCALLS* = [
  "exit_group", "socket", "connect", "getuid", "getpid", "rt_sigreturn", "exit", "mmap",
  "pipe2",
]

proc sandbox*() {.noinline.} =
  when not defined(ferusInJail):
    return

  info "Starting sandboxing via seccomp backend!"
  let ver = getVersion()

  info "Using seccomp@" & $ver[0] & '.' & $ver[1] & '.' & $ver[2]
  let ctx = seccompCtx(Allow)

  for forbidden in FORBIDDEN_SYSCALLS:
    info "Forbidding system call: " & forbidden
    ctx.addRule(Kill, forbidden)

  info "Applying context. Any violations beyond this point will result in program termination."
  load ctx
