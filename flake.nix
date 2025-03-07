{
  description = "Ferus is a web engine (HTML/CSS viewer) with JavaScript support written in Nim.";

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
              # nimble
              nph
              wayland-protocols
              wayland-scanner
              openssl
              cmake
              gnumake
            ];

            buildInputs = with pkgs; [
              pkg-config
              libxkbcommon
              libseccomp
              libGL
              glfw
              curl.dev

              xorg.libX11
              icu76
              libseccomp.dev
              fontconfig
              boehmgc
              gmp
              openssl.dev
              xorg.libXext

              wayland
            ];

            LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
              libGL
              simdutf
              openssl
              boehmgc
              curl.dev
              fontconfig.dev
              libseccomp.dev
              gmp.dev
              icu76.dev
            ];

            env = with pkgs; {
              PKG_CONFIG_PATH = builtins.concatStringsSep ":" (map (pkg: "${lib.makeLibraryPath [pkg]}/pkgconfig") 
                [ 
                  libGL
                  simdutf
                  openssl.dev
                  curl.dev
                  boehmgc.dev
                  libseccomp.dev
                  fontconfig.dev
                  gmp.dev
                  glfw
                  icu76.dev
                ]
              );
            };

            wrapFerus =
              let
                makeWrapperArgs = "--prefix LD_LIBRARY_PATH : ${LD_LIBRARY_PATH}";
              in
              ''
                wrapProgram ferus ${makeWrapperArgs}
                wrapProgram ferus_process ${makeWrapperArgs}
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
