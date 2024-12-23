{ pkgs, wld }:

pkgs.stdenv.mkDerivation rec {
  pname = "st-wl";
  version = "latest"; # Replace with the actual version if available

  # Source definition: replace with actual source location
  src = pkgs.fetchFromGitHub {
    owner = "deadlyshoes"; # Replace with the correct GitHub owner
    repo = "st-wl"; # Replace with the correct repository name
    rev = "master"; # Replace with the desired commit or branch
    sha256 =
      "sha256-BMT7nZeV6kp8X7CSLtbCSWw0N8twI699o1ZfPyCyCY8="; # Replace with the correct sha256 hash
  };

  patches = [ ]; # Add any required patches or replace with actual patch list

  # Optional configuration file handling
  # configFile =
  #  if conf != null then pkgs.writeText "config.def.h" conf else null;
  #preBuild = if conf != null then "cp ${configFile} config.def.h" else "";

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [
    pkgs.ncurses
    pkgs.wayland
    pkgs.wayland-protocols
    wld
    pkgs.libxkbcommon
    pkgs.fontconfig
    pkgs.pixman
    pkgs.freetype
    pkgs.xorg.libX11
    pkgs.xorg.libXft
  ];

  NIX_LDFLAGS = "-lfontconfig";

  installPhase = ''
    TERMINFO=$out/share/terminfo make install PREFIX=$out
  '';

  preFixup = ''
    mv $out/bin/st $out/bin/st-wl
  '';

  enableParallelBuilding = true;

  meta = {
    description = "A Wayland port of the st terminal emulator";
    homepage = "https://st.suckless.org/";
    #license = pkgs.stdenv.lib.licenses.mit;
    #platforms = pkgs.stdenv.lib.platforms.linux;
    maintainers = [ ]; # Add maintainers if needed
  };
}
