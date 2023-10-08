#!/usr/bin/env sh

nix-shell -p xorg.libX11 xorg.libX11.dev xorg.libXext xorg.libXext.dev libGL
