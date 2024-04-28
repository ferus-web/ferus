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

## Building using the Nix flake

If you'd like to build Ferus only once using the flake,
you can simply run

    nix build

and Ferus will be built and installed to the result/
subdirectory. `nix profile install` can be used to
install it to your home directory.
