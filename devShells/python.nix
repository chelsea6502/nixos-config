#!/usr/bin/env nix-shell
#!nix-shell -i bash

# Python FHS Environment for maximum pip install compatibility
# Usage: nix-shell devShells/python.nix
# This creates a traditional Linux-like environment where pip packages work reliably

{ pkgs ? import <nixpkgs> { } }:
let
  # Base packages always needed
  basePkgs = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.setuptools
    python3Packages.wheel
    gcc
    glibc
    pkg-config
    zlib
    stdenv.cc.cc
  ];
  
  # All packages included for comprehensive Python development
  conditionalPkgs = with pkgs; [
    # Math/Science libraries
    blas lapack openblas libffi
    
    # GUI/Graphics libraries
    glib gtk3 cairo pango gdk-pixbuf atk freetype fontconfig
    
    # Web/HTTP libraries
    curl openssl libssh
    
    # Database libraries
    sqlite
    
    # XML/parsing libraries
    libxml2 libxslt expat
    
    # Compression libraries
    bzip2 xz zstd
    
    # System utilities
    util-linux systemd
    
    # Crypto libraries
    libsodium
    
    # Terminal/CLI libraries
    ncurses readline
    
    # File attribute libraries
    attr acl
  ];

  base = pkgs.appimageTools.defaultFhsEnvArgs;
in
(pkgs.buildFHSEnv (base // {
  name = "python-fhs";
  targetPkgs = pkgs: basePkgs ++ conditionalPkgs;
  
  runScript = "bash";
  
  profile = ''
    echo "🐍 Python FHS Environment"
    echo "=========================="
    echo "Python: $(python3 --version)"
    echo "Pip: $(pip3 --version)"
    echo ""
    
    # Auto-setup if requirements.txt exists and no .venv
    if [ -f "requirements.txt" ] && [ ! -d ".venv" ]; then
      echo "🔄 Auto-setting up Python environment..."
      python3 -m venv .venv
      source .venv/bin/activate
      pip install -r requirements.txt
      echo "✅ Environment ready! Virtual environment is activated."
    elif [ -d ".venv" ]; then
      echo "🔄 Activating existing virtual environment..."
      source .venv/bin/activate
      echo "✅ Virtual environment activated: $(which python)"
    else
      echo "💡 Usage:"
      echo "  python3 -m venv .venv"
      echo "  source .venv/bin/activate"
      echo "  pip install numpy scipy matplotlib pandas"
    fi
  '';
  
  extraOutputsToInstall = [ "dev" ];
})).env