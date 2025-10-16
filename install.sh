#!/usr/bin/env bash
set -e

DISK=${1:-/dev/nvme1n1}
CONFIG=${2:-nixos}

echo "Installing NixOS with:"
echo "  Disk: $DISK"
echo "  Config: $CONFIG"
echo ""

# Enable flakes for the installation process
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
export NIX_CONFIG="experimental-features = nix-command flakes"

# Clone the configuration repository directly to /etc/nixos
# Remove existing /etc/nixos if it exists to avoid git clone conflicts
sudo rm -rf /etc/nixos
sudo git clone https://github.com/chelsea6502/nixos-config.git /etc/nixos
cd /etc/nixos

# Update the disk device in configuration.nix
sed -i "s|device = \"/dev/sda\"|device = \"$DISK\"|" configuration.nix

# Clear the disk before partitioning
echo "Clearing disk $DISK..."
sudo wipefs --all --force "$DISK" || true
sudo sgdisk --zap-all "$DISK" || true
echo "Disk cleared successfully."
echo ""

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
