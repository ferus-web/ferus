import std/logging, seccomp

const FORBIDDEN_SYSCALLS* = [
  # Deny I/O
  "write", "read", 

  "getpid", "alarm", 

  # Deny UDP since we're only using TCP
  "sendto", "recvfrom", 

  # Don't allow the process to start a TCP server
  "bind", "listen", 
  
  # misc
  "kill", "uname",
  "getcwd", "link", "readlink", "symlink",
  "chown", "sysinfo", "setgid", "getgid",
  "ptrace", "reboot", "sethostname",
  "init_module", "splice", "migrate_pages",
  "kexec_load"
]

proc sandbox* {.noinline.} =
  info "Starting sandboxing via seccomp backend!"
  let ver = getVersion()

  info "Using seccomp@" & $ver[0] & '.' & $ver[1] & '.' & $ver[2]
  let ctx = seccompCtx()
    
  for forbidden in FORBIDDEN_SYSCALLS:
    info "Forbidding syscall: " & forbidden
    ctx.addRule(Allow, forbidden)
  
  # allow these ones
  ctx.addRule(Allow, "exit_group")
  ctx.addRule(Allow, "rt_sigreturn")
  ctx.addRule(Allow, "exit")

  info "Applying context. Any violations beyond this point will result in program termination."
  load ctx
