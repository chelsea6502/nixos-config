#!/bin/sh

# Check if the device argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <device>"
  echo "Example: $0 /dev/vda"
  exit 1
fi

DEVICE="$1"

# Download the disko configuration
curl https://raw.githubusercontent.com/chelsea6502/nixos-config/main/disko.nix -o /tmp/disko.nix

# Run disko to partition and format the device
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko.nix --arg device "\"$DEVICE\""

# Clone the template repository to ensure Git and submodules are initialized
sudo git clone https://github.com/chelsea6502/nixos-config nixos

# Generate the NixOS configuration without filesystem entries
sudo nixos-generate-config --no-filesystems --root /mnt

# Copy the NixOS configuration to a persistent directory
sudo cp -r ./nixos/* /mnt/persist/system/etc/nixos/

# Install NixOS using the flake configuration
sudo nixos-install --root /mnt --flake /mnt/etc/nixos#nixos

# Copy public keys
sudo mkdir -p /mnt/persist/system/home/chelsea/.config/Yubico/
sudo cp ./nixos/keys/u2f_keys /mnt/persist/system/home/chelsea/.config/Yubico/
sudo mkdir -p /mnt/persist/system/home/chelsea/.ssh/
sudo cp ./nixos/keys/id_ed25519_sk.pub /mnt/persist/system/home/chelsea/.ssh/
