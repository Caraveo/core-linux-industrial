#!/bin/bash
#
# CORE Linux - Industrial Edition
# ISO Builder Script
#
# This script builds the complete CORE Linux ISO image
# including custom kernel, branding, and installer.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m'

# Build configuration
CORE_VERSION="1.0"
BUILD_ROOT="${CORE_BUILD_ROOT:-/opt/core-build}"
KERNEL_DIR="$BUILD_ROOT/kernel"
ISO_DIR="$BUILD_ROOT/iso"
BRANDING_DIR="$BUILD_ROOT/branding"
WORK_DIR="$BUILD_ROOT/work"
OUTPUT_DIR="$BUILD_ROOT/output"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   I N D U S T R I A L   E D I T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Building CORE Linux Industrial Edition ISO..."
echo "Version: $CORE_VERSION"
echo "Architecture: x86_64"
echo ""

# Source environment
if [[ -f /etc/profile.d/core-build.sh ]]; then
    source /etc/profile.d/core-build.sh
fi

# Create directories
mkdir -p "$KERNEL_DIR" "$ISO_DIR" "$BRANDING_DIR" "$WORK_DIR" "$OUTPUT_DIR"

# Function: Build custom kernel
build_kernel() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building Custom Kernel: CORE_Industrial"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$KERNEL_DIR"
    
    # Clone kernel if not present
    if [[ ! -d linux ]]; then
        echo "Cloning Linux kernel..."
        git clone --depth 1 --branch v6.1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
    fi
    
    cd linux
    
    # Clean previous build
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- distclean || true
    
    # Configure kernel
    echo "Configuring kernel..."
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- defconfig
    
    # Customize kernel config
    echo "Applying CORE Industrial customizations..."
    
    # Enable UEFI and legacy BIOS
    ./scripts/config --enable CONFIG_EFI
    ./scripts/config --enable CONFIG_EFI_STUB
    ./scripts/config --enable CONFIG_EFI_MIXED
    ./scripts/config --enable CONFIG_EFIVAR_FS
    
    # Enable storage drivers
    ./scripts/config --enable CONFIG_BLK_DEV_NVME
    ./scripts/config --enable CONFIG_ATA
    ./scripts/config --enable CONFIG_SATA_AHCI
    ./scripts/config --enable CONFIG_SATA_AHCI_PLATFORM
    
    # Enable WiFi
    ./scripts/config --enable CONFIG_WLAN
    ./scripts/config --enable CONFIG_CFG80211
    ./scripts/config --enable CONFIG_MAC80211
    ./scripts/config --module CONFIG_IWLWIFI
    ./scripts/config --module CONFIG_IWLMVM
    
    # Enable Intel iGPU
    ./scripts/config --enable CONFIG_DRM
    ./scripts/config --enable CONFIG_DRM_I915
    ./scripts/config --module CONFIG_DRM_I915
    
    # Set kernel name
    sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-CORE_Industrial"/' .config
    
    # Build kernel with progress output
    echo "Building kernel (this will take 30-60 minutes)..."
    echo "Progress will be shown below..."
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- -j$(nproc) KCFLAGS="-O2" 2>&1 | while IFS= read -r line; do
        echo "[$(date +%H:%M:%S)] $line"
    done
    
    # Build modules
    echo "Building kernel modules (this will take 10-20 minutes)..."
    echo "Progress will be shown below..."
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- -j$(nproc) modules 2>&1 | while IFS= read -r line; do
        echo "[$(date +%H:%M:%S)] $line"
    done
    
    # Install kernel and modules to staging
    KERNEL_STAGING="$WORK_DIR/kernel-staging"
    mkdir -p "$KERNEL_STAGING/boot" "$KERNEL_STAGING/lib/modules"
    
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- INSTALL_PATH="$KERNEL_STAGING/boot" install
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- INSTALL_MOD_PATH="$KERNEL_STAGING" modules_install
    
    echo "✓ Kernel build complete"
}

# Function: Create live-build configuration
setup_livebuild() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Setting up live-build configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$WORK_DIR"
    rm -rf core-live
    mkdir -p core-live
    cd core-live
    
    # Initialize live-build
    lb config \
        --architectures amd64 \
        --binary-images iso-hybrid \
        --distribution bookworm \
        --debian-installer false \
        --archive-areas "main contrib non-free" \
        --mirror-bootstrap "http://deb.debian.org/debian" \
        --mirror-chroot "http://deb.debian.org/debian" \
        --bootloader grub \
        --grub-splash "$BRANDING_DIR/grub/splash.png" || true
    
    # Create config directory structure
    mkdir -p config/includes.chroot
    mkdir -p config/includes.binary
    mkdir -p config/hooks
    mkdir -p config/package-lists
    
    # Custom packages list
    cat > config/package-lists/core.list.chroot << 'PKGLIST_EOF'
bash
nano
vim
htop
git
openssh-server
curl
wget
sudo
systemd
network-manager
dhcpcd5
PKGLIST_EOF
    
    # Custom os-release
    mkdir -p config/includes.chroot/etc
    cat > config/includes.chroot/etc/os-release << 'OSRELEASE_EOF'
NAME="CORE Linux"
PRETTY_NAME="CORE Linux - Industrial Edition"
ID=core
ID_LIKE=debian
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://core-linux.org"
SUPPORT_URL="https://core-linux.org/support"
BUG_REPORT_URL="https://core-linux.org/bugs"
OSRELEASE_EOF
    
    # Custom hostname
    echo "core-industrial" > config/includes.chroot/etc/hostname
    
    # Custom MOTD
    mkdir -p config/includes.chroot/etc
    cp "$BRANDING_DIR/ascii/motd" config/includes.chroot/etc/motd 2>/dev/null || true
    
    # Custom login banner
    mkdir -p config/includes.chroot/etc
    cp "$BRANDING_DIR/ascii/issue" config/includes.chroot/etc/issue 2>/dev/null || true
    cp "$BRANDING_DIR/ascii/issue.net" config/includes.chroot/etc/issue.net 2>/dev/null || true
    
    # GRUB theme
    mkdir -p config/includes.binary/usr/share/grub/themes/core-industrial
    cp -r "$BRANDING_DIR/grub"/* config/includes.binary/usr/share/grub/themes/core-industrial/ 2>/dev/null || true
    
    # GRUB configuration
    mkdir -p config/includes.binary/boot/grub
    cat > config/includes.binary/boot/grub/grub.cfg << 'GRUBCFG_EOF'
set timeout=5
set default=0

loadfont unicode
set gfxmode=auto
set gfxpayload=keep
insmod gfxterm
insmod vbe
insmod vga

set theme=/usr/share/grub/themes/core-industrial/theme.txt

menuentry "CORE Linux - Industrial Edition" {
    linux /vmlinuz boot=live quiet splash
    initrd /initrd.img
}

menuentry "CORE Linux - Industrial Edition (Safe Mode)" {
    linux /vmlinuz boot=live quiet splash nomodeset
    initrd /initrd.img
}
GRUBCFG_EOF
    
    # Post-install hook for installer
    mkdir -p config/hooks
    cat > config/hooks/9999-installer.chroot << 'HOOK_EOF'
#!/bin/bash
# CORE Linux installer setup

mkdir -p /usr/local/bin
cat > /usr/local/bin/core-install << 'INSTALLER_EOF'
#!/bin/bash
# CORE Linux Installation Script

set -euo pipefail

RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m'

clear
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   I N D U S T R I A L   E D I T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Installation Script"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Detect installation target
TARGET_DISK=$(whiptail --title "CORE Linux Installer" --inputbox "Enter target disk (e.g., /dev/sda):" 10 60 3>&1 1>&2 2>&3)
if [[ -z "$TARGET_DISK" ]]; then
    echo "Installation cancelled"
    exit 1
fi

# Partitioning
whiptail --title "Partitioning" --msgbox "Creating GPT partition table and partitions..." 10 60

parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 100%

TARGET_PART="${TARGET_DISK}1"
mkfs.ext4 -F "$TARGET_PART"

# Mount and install
MOUNT_POINT="/mnt/core-install"
mkdir -p "$MOUNT_POINT"
mount "$TARGET_PART" "$MOUNT_POINT"

# Debootstrap installation
whiptail --title "Installing CORE Linux" --msgbox "Installing base system (this will take a while)..." 10 60

debootstrap --arch amd64 bookworm "$MOUNT_POINT" http://deb.debian.org/debian

# Chroot setup
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /proc "$MOUNT_POINT/proc"
mount --bind /sys "$MOUNT_POINT/sys"

# Install GRUB
chroot "$MOUNT_POINT" /bin/bash << CHROOT_EOF
apt-get update
apt-get install -y grub-pc grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=CORE
update-grub
CHROOT_EOF

# Create user
USERNAME=$(whiptail --title "Create User" --inputbox "Enter username:" 10 60 core 3>&1 1>&2 2>&3)
if [[ -n "$USERNAME" ]]; then
    chroot "$MOUNT_POINT" /bin/bash << CHROOT_EOF
useradd -m -s /bin/bash "$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
CHROOT_EOF
fi

# Enable SSH
chroot "$MOUNT_POINT" systemctl enable ssh

# Unmount
umount "$MOUNT_POINT"/{sys,proc,dev}
umount "$MOUNT_POINT"

whiptail --title "Installation Complete" --msgbox "CORE Linux has been installed successfully!" 10 60
INSTALLER_EOF

chmod +x /usr/local/bin/core-install
HOOK_EOF
    
    chmod +x config/hooks/9999-installer.chroot
    
    echo "✓ Live-build configuration complete"
}

# Function: Build ISO
build_iso() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building ISO image"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$WORK_DIR/core-live"
    
    # Build the ISO with progress output
    echo "Building ISO (this will take 1-2 hours)..."
    echo "This is downloading packages and building the live system..."
    echo "Progress will be shown below with timestamps..."
    lb build 2>&1 | while IFS= read -r line; do
        echo "[$(date +%H:%M:%S)] $line"
        echo "$line" >> "$OUTPUT_DIR/build.log"
    done
    
    # Move ISO to output directory
    if [[ -f binary.hybrid.iso ]]; then
        ISO_NAME="core-industrial-${CORE_VERSION}-amd64.iso"
        mv binary.hybrid.iso "$OUTPUT_DIR/$ISO_NAME"
        echo "✓ ISO created: $OUTPUT_DIR/$ISO_NAME"
        
        # Generate checksum
        cd "$OUTPUT_DIR"
        sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"
        echo "✓ Checksum created: ${ISO_NAME}.sha256"
        
        # Display results
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ${GREY}Build Complete!${NC}                                 ${RED}║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Output files:"
        echo "  ISO: $OUTPUT_DIR/$ISO_NAME"
        echo "  Checksum: $OUTPUT_DIR/${ISO_NAME}.sha256"
        echo ""
        ls -lh "$OUTPUT_DIR/$ISO_NAME"
        echo ""
        cat "$OUTPUT_DIR/${ISO_NAME}.sha256"
    else
        echo -e "${RED}Error: ISO build failed${NC}"
        exit 1
    fi
}

# Main build process
main() {
    # Copy branding files if they exist
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    if [[ -d "$PROJECT_ROOT/branding" ]]; then
        cp -r "$PROJECT_ROOT/branding"/* "$BRANDING_DIR/" 2>/dev/null || true
    fi
    
    # Run build steps
    build_kernel
    setup_livebuild
    build_iso
    
    echo ""
    echo "CORE Linux Industrial Edition build complete!"
}

# Run main function
main

