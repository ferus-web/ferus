## Building Ferus

To build and run Ferus, install development packages for
the following libraries:

- libGL
- glfw
- libseccomp
- libxkbcommon
- libX11
- libXext
- wayland, wayland-protocols and wayland-scanner

When these are all installed, run

    nimble build

to build Ferus. The executable will be named `ferus` in
the current directory.

## Hacking on Ferus

Ferus provides a Nix flake which can be used to drop into
a development environment containing all the necessary tools
and libraries. If you're using Nix, all you have to do is run

    nix develop

and from there you can execute Nimble as usual to build Ferus.
If you're having trouble executing Ferus from another directory,
use the `build-ferus` shell function instead. This function is
activated whenever you enter a dev shell with `nix develop` and
passes all its arguments to `nimble build.`

## Building using the Nix flake

If you'd like to build Ferus only once using the flake,
you can simply run

    nix build

and Ferus will be built and installed to the result/
subdirectory. `nix profile install` can be used to
install it to your home directory.

## Compiling Ferus with a different windowing backend

Ferus supports windy and glfw as two windowing backends. We hope that windy one day will have a working Wayland backend, but until then, glfw is the default. To force Ferus to use windy, go into the `nim.cfg` file and comment out the compile-time define `ferusUseGlfw`.

## More compile-time flags for Ferus
### --define:ferusInJail

This will force all new processes to sandbox themselves appropriately. This is an unstable feature and will not be enabled by default until it is ready. It is much more secure than how Ferus currently works.

### --define:ferusSandboxAttachStrace

This exists for debugging the previously mentioned flag and adding more support for it. Ferus' child processes will be launched via `strace` if this flag is provided.

### --define:ferusAddMangohudToRendererPrefix

If provided, then Ferus' renderer will be started with `mangohud --dlsym`, providing a neat little overlay to see the framerate and other statistics.

### --define:ferusJustWaitForConnection

If provided, then Ferus' master spawner will not launch commands to summon new child processes itself, but wait for the user to type it out themselves. This is very useful for debugging the child processes, but gets annoying to do per-run fast.
