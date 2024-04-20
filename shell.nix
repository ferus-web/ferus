with import <nixpkgs> { };

mkShell {
  nativeBuildInputs = [
    xorg.libX11
    xorg.libX11.dev
    xorg.libXext
    xorg.libXext.dev
    libGL
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [
    libGL
    xorg.libXext.dev
    xorg.libX11.dev
  ];
}
