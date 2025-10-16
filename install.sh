#!/usr/bin/env bash
set -e

DISK=${1:-/dev/sda}
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
sed -i "s|device = \"/dev/nvme0n1\"|device = \"$DISK\"|" configuration.nix

# ============================================================================
# LUKS ENCRYPTION SETUP
# ============================================================================

echo -e "\n=== LUKS Encryption (Yubikey 1FA) ===\n"

# Helper functions
rbtohex() { od -An -vtx1 | tr -d ' \n'; }
hextorb() { tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf; }

# Compile pbkdf2-sha512
cat > /tmp/pbkdf2-sha512.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "Usage: %s <key_length> <iterations> <salt>\n", argv[0]); return 1; }
    int key_length = atoi(argv[1]), iterations = atoi(argv[2]);
    const char *salt = argv[3];
    unsigned char key[key_length];
    char password[1024];
    if (fgets(password, sizeof(password), stdin) == NULL) { fprintf(stderr, "Error reading password\n"); return 1; }
    size_t password_len = strlen(password);
    if (password_len > 0 && password[password_len - 1] == '\n') { password[password_len - 1] = '\0'; password_len--; }
    if (PKCS5_PBKDF2_HMAC(password, password_len, (unsigned char *)salt, strlen(salt), iterations, EVP_sha512(), key_length, key) == 0) {
        fprintf(stderr, "PBKDF2 failed\n"); return 1;
    }
    fwrite(key, 1, key_length, stdout);
    return 0;
}
EOF
gcc -o /tmp/pbkdf2-sha512 /tmp/pbkdf2-sha512.c -lcrypto && export PATH="/tmp:$PATH"

# Generate LUKS key from Yubikey
SALT="$(dd if=/dev/random bs=1 count=16 2>/dev/null | rbtohex)"
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
echo "Touch Yubikey..."
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)
LUKS_KEY="$(echo | pbkdf2-sha512 64 1000000 $RESPONSE | rbtohex)"
echo "LUKS key generated"

# ============================================================================
# DISK PARTITIONING
# ============================================================================

# Install disko and partition the disk
nix profile install nixpkgs#disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake ".#$CONFIG"

# ============================================================================
# LUKS DEVICE CREATION
# ============================================================================

echo -e "\nCreating LUKS device..."

# Determine root partition
[[ $DISK == *"nvme"* || $DISK == *"mmcblk"* ]] && ROOT_PARTITION="${DISK}p2" || ROOT_PARTITION="${DISK}2"

# Create and open LUKS device
sudo cryptsetup close cryptroot 2>/dev/null || true
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup luksFormat --cipher=aes-xts-plain64 --key-size=512 --hash=sha512 --key-file=- "$ROOT_PARTITION"
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup open "$ROOT_PARTITION" cryptroot --key-file=-

# Format and mount
sudo mkfs.ext4 /dev/mapper/cryptroot
sudo umount /mnt 2>/dev/null || true
sudo mount /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/boot
[[ $DISK == *"nvme"* || $DISK == *"mmcblk"* ]] && sudo mount "${DISK}p1" /mnt/boot || sudo mount "${DISK}1" /mnt/boot

# Store salt and iterations
sudo mkdir -p /mnt/boot/crypt-storage
echo -ne "$SALT\n1000000" | sudo tee /mnt/boot/crypt-storage/default > /dev/null
sudo chmod 600 /mnt/boot/crypt-storage/default

echo "LUKS setup complete"

# ============================================================================
# NIXOS INSTALLATION
# ============================================================================

# Generate hardware configuration
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos

# Copy configuration files from /etc/nixos to /mnt/etc/nixos
sudo cp -r /etc/nixos/* /mnt/etc/nixos/

# Install NixOS
nixos-install --root /mnt --flake "/mnt/etc/nixos#$CONFIG" --no-root-passwd
