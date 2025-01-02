{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ nodejs_22 ];

  shellHook = ''
    echo "Webdev shell activated!"
  '';
}
