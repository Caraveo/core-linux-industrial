#!/bin/bash
#
# CORE Linux - Industrial Edition
# macOS Host Setup Script
# 
# This script prepares your macOS M4 Apple Silicon host for building CORE Linux
# by installing dependencies and setting up the ARM64 Ubuntu VM environment.
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   I N D U S T R I A L   E D I T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Preparing macOS host for CORE Linux build environment..."
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    exit 1
fi

# Check for Apple Silicon
if [[ "$(uname -m)" != "arm64" ]]; then
    echo -e "${RED}Warning: This script is optimized for Apple Silicon (M4)${NC}"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if missing
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✓ Homebrew already installed"
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Install required tools
echo "Installing required tools..."
brew install curl wget git

# Check for UTM or Parallels
UTM_INSTALLED=false
PARALLELS_INSTALLED=false

if command_exists utmctl || [[ -d "/Applications/UTM.app" ]]; then
    UTM_INSTALLED=true
    echo "✓ UTM detected"
fi

if command_exists prlctl || [[ -d "/Applications/Parallels Desktop.app" ]]; then
    PARALLELS_INSTALLED=true
    echo "✓ Parallels Desktop detected"
fi

if [[ "$UTM_INSTALLED" == false && "$PARALLELS_INSTALLED" == false ]]; then
    echo ""
    echo -e "${RED}Warning: Neither UTM nor Parallels Desktop detected${NC}"
    echo "Please install one of the following:"
    echo "  - UTM: https://mac.getutm.app/"
    echo "  - Parallels Desktop: https://www.parallels.com/"
    echo ""
    echo "After installation, re-run this script."
    exit 1
fi

# Create VM directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_DIR="$PROJECT_ROOT/vm"
BUILD_DIR="$PROJECT_ROOT/build"

echo "Creating project directories..."
mkdir -p "$VM_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$PROJECT_ROOT/branding/grub"
mkdir -p "$PROJECT_ROOT/branding/ascii"

# Download Ubuntu ARM64 cloud image if not present
UBUNTU_IMAGE="$VM_DIR/ubuntu-22.04-server-cloudimg-arm64.img"
UBUNTU_URL="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img"

if [[ ! -f "$UBUNTU_IMAGE" ]]; then
    echo "Downloading Ubuntu 22.04 ARM64 cloud image..."
    echo "This may take several minutes..."
    curl -L -o "$UBUNTU_IMAGE" "$UBUNTU_URL"
    echo "✓ Ubuntu image downloaded"
else
    echo "✓ Ubuntu image already present"
fi

# Verify VM bootstrap script exists
if [[ -f "$PROJECT_ROOT/vm/vm-bootstrap.sh" ]]; then
    echo "✓ VM bootstrap script ready"
else
    echo -e "${RED}Warning: vm-bootstrap.sh not found in $PROJECT_ROOT/vm/${NC}"
fi

# Create instructions file
cat > "$VM_DIR/VM_SETUP_INSTRUCTIONS.txt" << 'INSTRUCTIONS_EOF'
CORE Linux - Industrial Edition
VM Setup Instructions
======================

After running setup-host.sh, you need to:

1. Create a new VM in UTM or Parallels:
   - Type: Linux
   - Architecture: ARM64
   - Memory: At least 8GB (16GB recommended)
   - Disk: At least 50GB
   - Use the downloaded Ubuntu cloud image

2. Start the VM and login

3. Copy vm-bootstrap.sh into the VM:
   - Use shared folders, or
   - SCP, or
   - Copy-paste the script content

4. Run inside VM:
   chmod +x vm-bootstrap.sh
   sudo ./vm-bootstrap.sh

5. After bootstrap completes, copy build-core.sh into VM

6. Run the build:
   chmod +x build-core.sh
   sudo ./build-core.sh

The ISO will be generated in the build directory.
INSTRUCTIONS_EOF

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}Setup Complete!${NC}                                 ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "1. Review: $VM_DIR/VM_SETUP_INSTRUCTIONS.txt"
echo "2. Create your ARM64 Ubuntu VM"
echo "3. Copy vm/vm-bootstrap.sh into the VM"
echo "4. Run the bootstrap script inside the VM"
echo ""
echo "Project structure:"
echo "  $PROJECT_ROOT"
echo "    ├── host/          (macOS scripts)"
echo "    ├── vm/            (VM provisioning)"
echo "    ├── build/         (ISO builder)"
echo "    └── branding/      (Themes and assets)"
echo ""

