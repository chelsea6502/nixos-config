{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "wld";
  version = "latest";

  # Replace with appropriate source fetching method
  src = pkgs.fetchFromGitHub {
    owner = "michaelforney"; # Replace with the correct GitHub owner
    repo = "wld"; # Replace with the correct repository name
    rev = "master"; # Replace with the desired commit or branch
    sha256 =
      "1sdhw8s26kaxx7d1sk8xf0jbxdmrk2whvx80i9z21vmh3vsf57w5"; # Replace with the correct sha256 hash
  };

  nativeBuildInputs = [ pkgs.pkg-config ];

  buildInputs = [
    pkgs.wayland
    pkgs.fontconfig
    pkgs.pixman
    pkgs.freetype
    pkgs.libdrm
    pkgs.wayland-scanner
  ];

  makeFlags = "PREFIX=$(out)";
  installPhase = "PREFIX=$out make install";

  enableParallelBuilding = true;

  meta = {
    description = "A primitive drawing library targeted at Wayland";
    homepage =
      "https://github.com/someOwner/wld"; # Replace with correct homepage
    #license = pkgs.stdenv.lib.licenses.mit;
    #platforms = pkgs.stdenv.lib.platforms.linux;
    maintainers = [ ];
  };
}
