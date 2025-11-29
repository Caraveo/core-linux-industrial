#!/bin/bash
#
# CORE Linux - Automated Build Guide
# This script checks prerequisites and guides you through the build process
#

set -euo pipefail

RED='\033[0;31m'
GREY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   B U I L D   G U I D E${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Prerequisites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ALL_GOOD=true

# Check Ubuntu image
if [[ -f "$SCRIPT_DIR/vm/ubuntu-22.04-server-cloudimg-arm64.img" ]]; then
    SIZE=$(du -h "$SCRIPT_DIR/vm/ubuntu-22.04-server-cloudimg-arm64.img" | cut -f1)
    echo -e "${GREEN}✓${NC} Ubuntu image: $SIZE"
else
    echo -e "${RED}✗${NC} Ubuntu image missing"
    echo "  Run: ./host/setup-host.sh"
    ALL_GOOD=false
fi

# Check VM software
HAS_VM=false
if command -v utmctl >/dev/null 2>&1 || [[ -d "/Applications/UTM.app" ]]; then
    echo -e "${GREEN}✓${NC} UTM detected"
    HAS_VM=true
    VM_TYPE="UTM"
elif command -v prlctl >/dev/null 2>&1 || [[ -d "/Applications/Parallels Desktop.app" ]]; then
    echo -e "${GREEN}✓${NC} Parallels Desktop detected"
    HAS_VM=true
    VM_TYPE="Parallels"
else
    echo -e "${RED}✗${NC} No VM software found"
    echo "  Install UTM: https://mac.getutm.app/"
    echo "  Or Parallels Desktop: https://www.parallels.com/"
    ALL_GOOD=false
fi

# Check scripts
for script in "host/setup-host.sh" "vm/vm-bootstrap.sh" "build/build-core.sh"; do
    if [[ -f "$SCRIPT_DIR/$script" ]] && [[ -x "$SCRIPT_DIR/$script" ]]; then
        echo -e "${GREEN}✓${NC} $script"
    else
        echo -e "${RED}✗${NC} $script missing or not executable"
        ALL_GOOD=false
    fi
done

echo ""

if [[ "$ALL_GOOD" == false ]]; then
    echo -e "${YELLOW}⚠ Some prerequisites are missing.${NC}"
    echo "Please fix the issues above and run this script again."
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met!${NC}"
echo ""

# Provide build instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Build Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$HAS_VM" == true ]]; then
    echo "STEP 1: Create ARM64 Ubuntu VM"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    
    if [[ "$VM_TYPE" == "UTM" ]]; then
        echo "Using UTM:"
        echo "  1. Open UTM"
        echo "  2. Click 'Create a New Virtual Machine'"
        echo "  3. Select 'Linux'"
        echo "  4. Choose 'Use an existing disk image'"
        echo "  5. Select: $SCRIPT_DIR/vm/ubuntu-22.04-server-cloudimg-arm64.img"
        echo "  6. Configure:"
        echo "     - Memory: 8GB minimum (16GB recommended)"
        echo "     - Disk: 50GB minimum"
        echo "  7. Start the VM"
        echo ""
    else
        echo "Using Parallels Desktop:"
        echo "  1. Open Parallels Desktop"
        echo "  2. File → New → From Image"
        echo "  3. Select: $SCRIPT_DIR/vm/ubuntu-22.04-server-cloudimg-arm64.img"
        echo "  4. Configure:"
        echo "     - Memory: 8GB minimum (16GB recommended)"
        echo "     - Disk: 50GB minimum"
        echo "  5. Start the VM"
        echo ""
    fi
    
    echo "STEP 2: Setup Shared Folder (Recommended)"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    echo "In your VM settings, add a shared folder pointing to:"
    echo "  $SCRIPT_DIR"
    echo ""
    echo "This allows easy file transfer between host and VM."
    echo ""
    
    echo "STEP 3: Bootstrap the VM"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    echo "Inside the VM, run these commands:"
    echo ""
    echo -e "${GREEN}# If using shared folder:${NC}"
    echo "  cd /path/to/shared/CORE"
    echo "  sudo ./vm/vm-bootstrap.sh"
    echo ""
    echo -e "${GREEN}# Or copy files manually:${NC}"
    echo "  # Copy vm-bootstrap.sh into VM"
    echo "  chmod +x vm-bootstrap.sh"
    echo "  sudo ./vm-bootstrap.sh"
    echo ""
    echo "This will take about 10-15 minutes to install all build tools."
    echo ""
    
    echo "STEP 4: Build CORE Linux ISO"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    echo "After bootstrap completes, inside the VM:"
    echo ""
    echo -e "${GREEN}# If using shared folder:${NC}"
    echo "  cd /path/to/shared/CORE"
    echo "  sudo ./build/build-core.sh"
    echo ""
    echo -e "${GREEN}# Or copy files manually:${NC}"
    echo "  # Copy build-core.sh and branding/ directory into VM"
    echo "  chmod +x build-core.sh"
    echo "  sudo ./build-core.sh"
    echo ""
    echo -e "${YELLOW}⚠ This will take 2-4 hours!${NC}"
    echo "The script will:"
    echo "  - Clone and build Linux kernel (CORE_Industrial)"
    echo "  - Configure live-build system"
    echo "  - Build complete ISO image"
    echo ""
    echo "Monitor progress:"
    echo "  tail -f /opt/core-build/output/build.log"
    echo ""
    
    echo "STEP 5: Get Your ISO"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    echo "After build completes, your ISO will be at:"
    echo "  /opt/core-build/output/core-industrial-1.0-amd64.iso"
    echo ""
    echo "Copy it to macOS using shared folder or SCP:"
    echo "  scp user@vm-ip:/opt/core-build/output/core-industrial-1.0-amd64.iso ./"
    echo ""
    
else
    echo "Please install UTM or Parallels Desktop first."
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Quick Reference Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Inside VM - Bootstrap:"
echo "  sudo ./vm/vm-bootstrap.sh"
echo ""
echo "Inside VM - Build:"
echo "  sudo ./build/build-core.sh"
echo ""
echo "Check build progress:"
echo "  tail -f /opt/core-build/output/build.log"
echo ""
echo "Verify ISO:"
echo "  ls -lh /opt/core-build/output/"
echo "  sha256sum -c /opt/core-build/output/*.sha256"
echo ""

