#!/bin/bash
#
# CORE Linux - Industrial Edition
# ARM64 Ubuntu VM Bootstrap Script
#
# This script installs all required build tools and dependencies
# for cross-compiling CORE Linux x86_64 ISO on ARM64 Ubuntu.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   I N D U S T R I A L   E D I T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Bootstrapping ARM64 Ubuntu VM for CORE Linux build..."
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    echo -e "${RED}Warning: This script is designed for ARM64 (aarch64) systems${NC}"
fi

# Update package lists
echo "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive

# Enable multiarch for x86_64 packages (needed for GRUB and cross-compilation)
echo "Enabling multiarch support for x86_64..."
dpkg --add-architecture amd64

# Configure apt to use standard Ubuntu archive for amd64 packages
# (ports.ubuntu.com doesn't have amd64 packages)
echo "Configuring apt sources for amd64 architecture..."

# First, restrict existing ports.ubuntu.com entries to arm64 only
if ! grep -q "deb \[arch=arm64\]" /etc/apt/sources.list; then
    echo "Restricting existing sources to arm64 architecture..."
    sed -i 's|^deb http://ports.ubuntu.com/ubuntu-ports|deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports|g' /etc/apt/sources.list
fi

# Add standard Ubuntu repositories for amd64 if not already present
if ! grep -q "deb \[arch=amd64\]" /etc/apt/sources.list; then
    echo "Adding standard Ubuntu repositories for amd64..."
    cat >> /etc/apt/sources.list << 'EOF'
# Standard Ubuntu repositories for amd64 (cross-compilation)
deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse
deb [arch=amd64] http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF
fi

apt-get update -qq

# Install essential build tools (required)
echo "Installing build essentials..."
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    debootstrap \
    live-build \
    gcc-x86-64-linux-gnu \
    g++-x86-64-linux-gnu \
    binutils-x86-64-linux-gnu \
    xorriso \
    squashfs-tools \
    dialog \
    whiptail \
    rsync \
    dosfstools \
    mtools \
    isolinux \
    syslinux \
    cpio \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zstd \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    kmod \
    pkg-config || {
    echo -e "${RED}Error: Failed to install essential packages${NC}"
    exit 1
}

# Install GRUB packages (optional, for ISO bootloader)
echo "Installing GRUB packages (for ISO bootloader)..."
apt-get install -y grub-common grub2-common || echo "Warning: GRUB packages not available, continuing..."
apt-get install -y grub-efi-amd64-bin:amd64 2>/dev/null || echo "Warning: grub-efi-amd64-bin:amd64 not available, will use alternatives"

# Install additional tools for kernel building (optional)
echo "Installing kernel build dependencies..."
apt-get install -y \
    libc6-dev \
    linux-libc-dev || echo "Warning: Some kernel build dependencies not available"

# Try to install cross-architecture dev packages (may not be available)
apt-get install -y libc6-dev-amd64-cross linux-libc-dev-amd64-cross 2>/dev/null || \
    echo "Warning: Cross-architecture dev packages not available, continuing..."

# Verify cross-compiler installation
echo "Verifying cross-compilation toolchain..."
if command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
    echo "✓ x86_64-linux-gnu-gcc: $(x86_64-linux-gnu-gcc --version | head -n1)"
else
    echo -e "${RED}Error: x86_64-linux-gnu-gcc not found${NC}"
    exit 1
fi

# Create build directories
BUILD_ROOT="/opt/core-build"
mkdir -p "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/kernel"
mkdir -p "$BUILD_ROOT/iso"
mkdir -p "$BUILD_ROOT/branding"
mkdir -p "$BUILD_ROOT/output"

echo "✓ Build directories created at $BUILD_ROOT"

# Set up environment variables
cat > /etc/profile.d/core-build.sh << 'ENV_EOF'
export CORE_BUILD_ROOT="/opt/core-build"
export ARCH=x86_64
export CROSS_COMPILE=x86_64-linux-gnu-
export PATH="/opt/core-build/bin:$PATH"
ENV_EOF

chmod +x /etc/profile.d/core-build.sh

# Source the environment
source /etc/profile.d/core-build.sh

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}Bootstrap Complete!${NC}                              ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "The VM is now ready for building CORE Linux."
echo ""
echo "Next steps:"
echo "1. Copy build-core.sh into this VM"
echo "2. Run: sudo ./build-core.sh"
echo ""
echo "Build environment:"
echo "  Build root: $BUILD_ROOT"
echo "  Cross-compiler: x86_64-linux-gnu-gcc"
echo "  Target arch: x86_64"
echo ""
