{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [
    pkgs.wayland
    pkgs.fontconfig
    pkgs.pixman
    pkgs.freetype
    pkgs.libdrm
    pkgs.ncurses
    pkgs.wayland-protocols
    pkgs.libxkbcommon
    pkgs.xorg.libX11
    pkgs.xorg.libXft
  ];
}
