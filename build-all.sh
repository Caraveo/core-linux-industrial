#!/bin/bash
#
# CORE Linux - Complete Automated Build
# This script does EVERYTHING automatically
#

set -euxo pipefail  # -x for verbose, -u for unset vars, -e for errors

RED='\033[0;31m'
GREY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   F U L L   A U T O M A T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This script will:"
echo "  1. Delete existing VM (if present) for clean build"
echo "  2. Install Lima (if needed)"
echo "  3. Create and configure Ubuntu VM"
echo "  4. Bootstrap the VM with build tools"
echo "  5. Build CORE Linux ISO"
echo "  6. Copy ISO to macOS"
echo ""
# Auto-continue if running non-interactively
if [[ -t 0 ]]; then
    read -p "Continue? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n "$REPLY" ]]; then
        exit 0
    fi
fi

VM_NAME="core-build"

# Step 0: Delete existing VM if present
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 0: Cleaning up existing VM (if present)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if limactl list | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}Found existing VM '$VM_NAME'. Deleting for clean build...${NC}"
    # Stop VM if running
    if limactl list | grep "$VM_NAME" | grep -q "Running"; then
        echo "Stopping VM..."
        limactl stop "$VM_NAME" || true
        sleep 2
    fi
    # Delete VM
    echo "Deleting VM..."
    limactl delete "$VM_NAME" || true
    echo -e "${GREEN}✓ Existing VM deleted${NC}"
else
    echo "No existing VM found. Starting fresh."
fi
echo ""

# Step 1: Setup Lima VM
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Setting up Lima VM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating Ubuntu 22.04 ARM64 VM with Lima..."
echo ""
"$SCRIPT_DIR/host/setup-lima.sh"
echo ""
echo "✓ Step 1 Complete: VM is running"

# Step 2: Bootstrap VM
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Bootstrapping VM (10-15 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing build tools and cross-compilation toolchain..."
echo ""
"$SCRIPT_DIR/host/bootstrap-vm.sh"
echo ""
echo "✓ Step 2 Complete: VM is bootstrapped"

# Step 3: Build ISO
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Building ISO (2-4 hours) ⏰"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This is the longest step - building kernel and ISO..."
echo "All output will be shown below and saved to logs."
echo ""
"$SCRIPT_DIR/host/build-iso.sh"
echo ""
echo "✓ Step 3 Complete: ISO built"

# Step 4: Copy ISO
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Copying ISO to macOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OUTPUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUTPUT_DIR"

echo "Copying ISO..."
limactl copy-from-vm "$VM_NAME" /opt/core-build/output/core-industrial-1.0-amd64.iso "$OUTPUT_DIR/" || {
    echo -e "${YELLOW}Warning: Could not copy ISO automatically${NC}"
    echo "Copy manually with:"
    echo "  limactl copy-from-vm $VM_NAME /opt/core-build/output/core-industrial-1.0-amd64.iso ./"
}

if [[ -f "$OUTPUT_DIR/core-industrial-1.0-amd64.iso" ]]; then
    echo -e "${GREEN}✓ ISO copied to: $OUTPUT_DIR/core-industrial-1.0-amd64.iso${NC}"
    ls -lh "$OUTPUT_DIR/core-industrial-1.0-amd64.iso"
fi

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}B U I L D   C O M P L E T E !${NC}                    ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your CORE Linux ISO is ready!"
echo ""

