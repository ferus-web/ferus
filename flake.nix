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
          default = pkgs.buildNimPackage rec {
            name = "ferus";
            src = ./.;

            lockFile = ./package.lock;

            nativeBuildInputs = with pkgs; [
              makeBinaryWrapper
              nimble
              wayland-protocols
              wayland-scanner
            ];

            buildInputs = with pkgs; [
              libxkbcommon
              libseccomp
              libGL
              glfw

              xorg.libX11
              xorg.libXext

              wayland
            ];

            LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
              libGL
            ];

            wrapFerus =
              let
                makeWrapperArgs = ''
                  --prefix LD_LIBRARY_PATH : ${LD_LIBRARY_PATH}
                '';
              in
              ''
                wrapProgram "$(pwd)"/ferus ${makeWrapperArgs}
                wrapProgram "$(pwd)"/ferus_process ${makeWrapperArgs}
              '';

            postInstall = ''
              cd $out/bin/
              ${wrapFerus}
            '';

            shellHook = ''
              build-ferus () {
                nimble build $@
                ${wrapFerus}
              }
            '';
          };
        });
      };
}
