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

# Clear and partition the disk
echo "Clearing disk $DISK..."
sudo wipefs --all --force "$DISK" || true
sudo sgdisk --zap-all "$DISK" || true
echo "Disk cleared."

echo "Partitioning $DISK..."
sudo parted -s "$DISK" mklabel gpt
sudo parted -s "$DISK" mkpart ESP fat32 1MiB 501MiB
sudo parted -s "$DISK" set 1 esp on
sudo parted -s "$DISK" mkpart root ext4 501MiB 100%

# Determine partition naming (nvme uses p1/p2, others use 1/2)
if [[ "$DISK" == *"nvme"* ]]; then
  PART1="${DISK}p1"
  PART2="${DISK}p2"
else
  PART1="${DISK}1"
  PART2="${DISK}2"
fi

echo "Formatting partitions..."
sudo mkfs.vfat -F32 "$PART1"
sudo mkfs.ext4 -F "$PART2"

echo "Mounting filesystems..."
sudo mount "$PART2" /mnt
sudo mkdir -p /mnt/boot
sudo mount "$PART1" /mnt/boot
echo "Disk setup complete."
echo ""

# Generate hardware configuration (includes filesystem entries)
nixos-generate-config --root /mnt --dir /mnt/etc/nixos

# Copy configuration files from /etc/nixos to /mnt/etc/nixos
sudo cp -r /etc/nixos/* /mnt/etc/nixos/

# Install NixOS
nixos-install --root /mnt --flake "/mnt/etc/nixos#$CONFIG" --no-root-passwd

echo "Installation complete! Reboot to start your new NixOS system."
