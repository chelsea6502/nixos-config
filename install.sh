#!/usr/bin/env bash
set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <disk> <config>"
    echo "Example: $0 /dev/sda nixos"
    exit 1
fi

DISK=$1
CONFIG=$2

# Enable flakes for the installation process
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
export NIX_CONFIG="experimental-features = nix-command flakes"

# Add cachix binary caches to speed up installation
nix profile install nixpkgs#cachix
cachix use nix-community
cachix use nixvim
cachix use stylix
cachix use mic92

git clone https://github.com/chelsea6502/nixos-config.git /tmp/nixos-config
cd /tmp/nixos-config
nix profile install nixpkgs#disko
disko --mode disko --arg device "\"$DISK\"" ./disko.nix
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos
cp -r * /mnt/etc/nixos/
nixos-install --root /mnt --flake "/mnt/etc/nixos#$CONFIG" --no-root-passwd
echo "Installation complete! Reboot to start your new NixOS system."