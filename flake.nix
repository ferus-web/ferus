{
  description = "web engine";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  };

  outputs = { self, nixpkgs }:
    with nixpkgs.lib;
    let
      forAllSystems = fn:
        genAttrs platforms.unix (system:
          fn (import nixpkgs {
            inherit system;
          })
        );
    in
      {
        packages = forAllSystems (pkgs: {
          default = pkgs.buildNimPackage {
            name = "ferus";
            src = ./.;

            lockFile = ./package.lock;

            nativeBuildInputs = with pkgs; [
              makeBinaryWrapper
              wayland-protocols
            ];

            buildInputs = with pkgs; [
              libxkbcommon
              libseccomp
              libGL
              glfw

              xorg.libX11
              xorg.libXext

              wayland
              wayland-scanner
            ];

            postInstall =
              with pkgs;
              let
                makeWrapperArgs = ''
                  --prefix LD_LIBRARY_PATH : \
                    ${lib.makeLibraryPath [ libGL ]}
                '';
              in
              ''
                wrapProgram $out/bin/ferus ${makeWrapperArgs}
                wrapProgram $out/bin/ferus_process ${makeWrapperArgs}
              '';
          };
        });
      };
}
