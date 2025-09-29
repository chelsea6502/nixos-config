#!/usr/bin/env nix-shell
#!nix-shell -i bash

# Python FHS Environment for maximum pip install compatibility
# Usage: nix-shell python-fhs.nix
# This creates a traditional Linux-like environment where pip packages work reliably

{ pkgs ? import <nixpkgs> { } }:
(
  let base = pkgs.appimageTools.defaultFhsEnvArgs; in
  pkgs.buildFHSEnv (base // {
    name = "python-fhs";
    targetPkgs = pkgs: (with pkgs; [
      # Python essentials
      python3
      python3Packages.pip
      python3Packages.virtualenv
      python3Packages.setuptools
      python3Packages.wheel
      
      # Build tools
      gcc
      glibc
      pkg-config
      
      # Core system libraries (from nix-ld)
      zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
      
      # GUI/Graphics libraries
      glib gtk3 cairo pango gdk-pixbuf atk
      
      # Development libraries
      libffi ncurses readline sqlite
      
      # Math/Science libraries
      blas lapack openblas
      
      # Font/Graphics
      freetype fontconfig
      
      # Additional common dependencies
      expat libxml2 libxslt
    ]);
    
    runScript = "bash";
    
    profile = ''
      echo "🐍 Python FHS Environment"
      echo "=========================="
      echo "This environment provides maximum compatibility for pip install"
      echo "including packages with compiled binaries like numpy, scipy, etc."
      echo ""
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
        echo "� Usage:"
        echo "  python3 -m venv .venv"
        echo "  source .venv/bin/activate"
        echo "  pip install numpy scipy matplotlib pandas"
      fi
      echo ""
      echo "🔧 This environment mimics a traditional Linux system"
      echo "   where compiled packages can find all needed libraries."
    '';
    
    extraOutputsToInstall = [ "dev" ];
  })
).env