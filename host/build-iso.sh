#!/bin/bash
#
# CORE Linux - Build ISO via Lima
#

set -euxo pipefail  # -x for verbose command tracing

RED='\033[0;31m'
GREY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VM_NAME="core-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}B U I L D I N G   C O R E   L I N U X   I S O${NC}        ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠ This will take 2-4 hours!${NC}"
echo ""

# Check if VM exists
if ! limactl list 2>/dev/null | grep -q "$VM_NAME"; then
    echo -e "${RED}Error: VM '$VM_NAME' not found${NC}"
    echo "Run: ./host/setup-lima.sh first"
    exit 1
fi

# Start VM if not running
if ! limactl list 2>/dev/null | grep "$VM_NAME" | grep -q "Running"; then
    echo "Starting VM..."
    limactl start "$VM_NAME"
    sleep 5
fi

# Copy branding if needed
echo "Ensuring branding files are in VM..."
limactl shell "$VM_NAME" -- mkdir -p /opt/core-build/branding
# Copy branding via mounted directory or base64
if [[ -d "/mnt/CORE/branding" ]]; then
    limactl shell "$VM_NAME" -- cp -r /mnt/CORE/branding /opt/core-build/ 2>/dev/null || true
fi

# Run build script
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Starting ISO build..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This will take 2-4 hours!"
echo ""
echo "Build process:"
echo "  1. Clone Linux kernel source"
echo "  2. Configure and build CORE_Industrial kernel"
echo "  3. Setup live-build configuration"
echo "  4. Build ISO image"
echo ""
echo "Monitor progress in another terminal:"
echo "  limactl shell $VM_NAME"
echo "  tail -f /opt/core-build/output/build.log"
echo ""

# Verify files are ready
echo "Verifying build environment..."
limactl shell "$VM_NAME" -- ls -lh /tmp/build-core.sh
limactl shell "$VM_NAME" -- test -d /tmp/branding && echo "✓ Branding files ready" || echo "⚠ Branding files missing"

# Run build with verbose output
echo ""
echo "Starting build (verbose mode)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All output will be displayed in real-time below:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run with unbuffered output and verbose flags
# Use script command for better output capture, or stdbuf if available
if command -v stdbuf >/dev/null 2>&1; then
    limactl shell "$VM_NAME" -- sudo bash -x -c "
        export BRANDING_DIR=/tmp/branding
        export CORE_BUILD_ROOT=/opt/core-build
        export PS4='+ [BUILD] '
        set -x
        bash -x /tmp/build-core.sh
    " 2>&1 | stdbuf -oL -eL tee /tmp/core-build.log
else
    # Fallback: use script or just direct output
    limactl shell "$VM_NAME" -- sudo bash -x -c "
        export BRANDING_DIR=/tmp/branding
        export CORE_BUILD_ROOT=/opt/core-build
        export PS4='+ [BUILD] '
        set -x
        bash -x /tmp/build-core.sh
    " 2>&1 | tee /tmp/core-build.log
fi

echo ""
echo -e "${GREEN}✓ Build complete!${NC}"
echo ""
echo "Your ISO is at: /opt/core-build/output/core-industrial-1.0-amd64.iso"
echo ""
echo "To copy to macOS:"
echo "  limactl copy-from-vm $VM_NAME /opt/core-build/output/core-industrial-1.0-amd64.iso ./"
echo ""

