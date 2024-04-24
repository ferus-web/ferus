with import <nixpkgs> { };

mkShell {
  nativeBuildInputs = [
    xorg.libX11
    xorg.libX11.dev
    xorg.libXext
    xorg.libXext.dev

    wayland.dev
    wayland-protocols
    wayland-scanner.dev
    libxkbcommon.dev
    libseccomp.dev
    libGL
    glfw
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [
    libGL
    xorg.libXext.dev
    xorg.libX11.dev
    wayland.dev
    libxkbcommon.dev
    wayland-scanner.dev
    glfw
    libseccomp.dev
  ];
}
