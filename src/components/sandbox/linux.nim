## Sandbox implementation for Linux using libseccomp

import std/[logging, posix]
import pkg/[seccomp, seccomp/seccomp_lowlevel]
import ../../components/ipc/shared

const FORBIDDEN_SYSCALLS* = [
  # Don't allow the process to start a TCP server
  "bind",
  "listen",

  # Don't allow this process to open a file

  # misc
  "kill",
  "getcwd",
  "link",
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
  "exit_group", "getuid", "getpid", "rt_sigreturn", "exit", "mmap", "munmap",
  "mprotect", "brk", "madvise", "shmat", "pipe2", "recvmsg", "recvfrom", "sendto",
  "sendmsg", "shmdt", "mlock", "mlock2", "munlock", "mlockall", "munlockall", "futex",
  "sched_yield", "clone", "wait4", "close", "readlink", "write", "read",
  "restart_syscall", "openat",
]

proc networkProcessSandbox*(ctx: ScmpFilterCtx) =
  for generalSyscall in ALLOWED_SYSCALLS:
    ctx.addRule(Allow, generalSyscall)

  for generalSyscall in FORBIDDEN_SYSCALLS:
    ctx.addRule(Kill, generalSyscall)

  # Socket functions, as this process will make sockets, connect with them, and destroy them
  ctx.addRule(Allow, "socket")
  ctx.addRule(Allow, "connect")
  ctx.addRule(Kill, "open")

proc rendererProcessSandbox*(ctx: ScmpFilterCtx) =
  ## The renderer process' sandbox is to be applied after the window has been initialized, otherwise calls via libwayland-client and libxcb would fail.
  for generalSyscall in ALLOWED_SYSCALLS:
    ctx.addRule(Allow, generalSyscall)

  for generalSyscall in FORBIDDEN_SYSCALLS:
    ctx.addRule(Kill, generalSyscall)

  ctx.addRule(Allow, "ioctl")
  ctx.addRule(Allow, "poll")
  ctx.addRule(Allow, "writev")
  ctx.addRule(Allow, "memfd_create")
  ctx.addRule(Allow, "ftruncate") # FIXME: isn't this a bit risky?
  ctx.addRule(Allow, "sched_setaffinity")
  ctx.addRule(Allow, "rt_sigprocmask")
  ctx.addRule(Allow, "clone3")

  ctx.addRule(Kill, "socket")
  ctx.addRule(Kill, "connect")
  ctx.addRule(Kill, "open")

proc parserProcessSandbox*(ctx: ScmpFilterCtx) =
  ## This is one of the most locked down processes as it is the most unsafe one (dealing with unsanitized input), but it also barely needs any syscalls to work.
  for generalSyscall in ALLOWED_SYSCALLS:
    ctx.addRule(Allow, generalSyscall)

  for generalSyscall in FORBIDDEN_SYSCALLS:
    ctx.addRule(Kill, generalSyscall)

  ctx.addRule(Kill, "socket")
  ctx.addRule(Kill, "connect")
  ctx.addRule(Kill, "ioctl")
  ctx.addRule(Kill, "open")

proc sandbox*(kind: FerusProcessKind) {.noinline.} =
  when not defined(ferusInJail):
    return

  info "Starting sandboxing via seccomp backend for " & $kind
  let ver = getVersion()

  info "Using seccomp@" & $ver[0] & '.' & $ver[1] & '.' & $ver[2]
  let ctx = seccompCtx(Kill)

  case kind
  of Network:
    networkProcessSandbox(ctx)
  of Renderer:
    rendererProcessSandbox(ctx)
  of Parser:
    parserProcessSandbox(ctx)
  else:
    error "Unhandled process for sandbox rules: " & $kind
    error "Quitting..."
    quit(1)

  onSignal SIGSYS:
    error "A syscall was executed which is in violation of the filter for this process"

  info "Applying context. Any violations beyond this point will result in program termination."
  load ctx
