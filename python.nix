#!/usr/bin/env nix-shell
#!nix-shell -i bash

# Python FHS Environment for maximum pip install compatibility
# Usage: nix-shell python.nix
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
  
  # All system libraries for comprehensive Python development
  systemPkgs = with pkgs; [
    # Math/Science libraries (numpy, scipy, pandas, matplotlib)
    blas lapack openblas libffi
    
    # GUI/Graphics libraries (tkinter, PyQt, PySide, matplotlib, pillow)
    glib gtk3 cairo pango gdk-pixbuf atk freetype fontconfig
    
    # Web/HTTP libraries (requests, urllib3, httpx, aiohttp)
    curl openssl libssh
    
    # Database libraries (sqlite, psycopg, pymongo)
    sqlite
    
    # XML/parsing libraries (lxml, beautifulsoup, xml)
    libxml2 libxslt expat
    
    # Compression libraries (zipfile, tarfile, gzip)
    bzip2 xz zstd
    
    # System utilities (psutil)
    util-linux systemd
    
    # Crypto libraries (cryptography, pycrypto)
    libsodium
    
    # Terminal/CLI libraries (click, readline)
    ncurses readline
    
    # File attribute libraries (xattr)
    attr acl
  ];

  base = pkgs.appimageTools.defaultFhsEnvArgs;
in
(pkgs.buildFHSEnv (base // {
  name = "python-fhs";
  targetPkgs = pkgs: basePkgs ++ systemPkgs;
  
  runScript = "bash";
  
  profile = ''
    echo "🐍 Python FHS Environment - $(python3 --version)"
    
    # Auto-setup if requirements.txt exists and no .venv
    if [ -f "requirements.txt" ] && [ ! -d ".venv" ]; then
      echo "🔄 Setting up virtual environment..."
      python3 -m venv .venv
      source .venv/bin/activate
      pip install -r requirements.txt
      echo "✅ Ready!"
    elif [ -d ".venv" ]; then
      echo "🔄 Activating virtual environment..."
      source .venv/bin/activate
      echo "✅ Activated: $(which python)"
    fi
  '';
  
  extraOutputsToInstall = [ "dev" ];
})).env