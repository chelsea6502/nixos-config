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

# Clone the configuration repository directly to /etc/nixos
sudo mkdir -p /etc/nixos
sudo git clone https://github.com/chelsea6502/nixos-config.git /etc/nixos
cd /etc/nixos

# Update the disk device in configuration.nix
sed -i "s|device = \"/dev/sda\"|device = \"$DISK\"|" configuration.nix

# Install disko and partition the disk
nix profile install nixpkgs#disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake ".#$CONFIG"

# Generate hardware configuration
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos

# Copy configuration files from /etc/nixos to /mnt/etc/nixos
sudo cp -r /etc/nixos/* /mnt/etc/nixos/

# Install NixOS
nixos-install --root /mnt --flake "/mnt/etc/nixos#$CONFIG" --no-root-passwd

echo "Installation complete! Reboot to start your new NixOS system."