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
cachix use nixpkgs-wayland

# Clone the configuration repository
git clone https://github.com/chelsea6502/nixos-config.git /tmp/nixos-config
cd /tmp/nixos-config

# Update the disk device in configuration.nix
sed -i "s|device = \"/dev/sda\"|device = \"$DISK\"|" configuration.nix

# Install disko and partition the disk
nix profile install nixpkgs#disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake ".#$CONFIG"

# Generate hardware configuration
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos

# Copy configuration files to /mnt/etc/nixos
cp -r * /mnt/etc/nixos/

# Install NixOS
nixos-install --root /mnt --flake "/mnt/etc/nixos#$CONFIG" --no-root-passwd

echo "Installation complete! Reboot to start your new NixOS system."