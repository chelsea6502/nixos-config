{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ (nodejs_22) typescript ];

  shellHook = ''
    echo "Welcome to a shell with Node.js 18.x and TypeScript 5.2.2!"
  '';
}
