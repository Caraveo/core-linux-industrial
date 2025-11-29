#!/bin/bash
#
# CORE Linux - Bootstrap VM via Lima
#

set -euxo pipefail  # -x for verbose command tracing

RED='\033[0;31m'
GREY='\033[0;90m'
GREEN='\033[0;32m'
NC='\033[0m'

VM_NAME="core-build"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}B O O T S T R A P P I N G   V M${NC}                      ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if VM exists
if ! limactl list | grep -q "$VM_NAME"; then
    echo -e "${RED}Error: VM '$VM_NAME' not found${NC}"
    echo "Run: ./host/setup-lima.sh first"
    exit 1
fi

# Start VM if not running
if ! limactl list | grep "$VM_NAME" | grep -q "Running"; then
    echo "Starting VM..."
    limactl start "$VM_NAME"
    sleep 5
fi

# Run bootstrap script
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running bootstrap script in VM..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This will take 10-15 minutes..."
echo "Installing: build tools, cross-compilers, live-build, etc."
echo ""

# Show what we're about to run
echo "Script location: /tmp/vm-bootstrap.sh"
limactl shell "$VM_NAME" -- ls -lh /tmp/vm-bootstrap.sh
echo ""

# Run with verbose output (unbuffered for real-time display)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Bootstrap Time Estimate: 10-15 minutes"
echo "Installing: build tools, cross-compilers, live-build, etc."
echo ""
echo "All output will be displayed in real-time below with timestamps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

limactl shell "$VM_NAME" -- sudo bash -x -c "
    export PS4='+ [\$(date +%H:%M:%S)] '
    bash -x /tmp/vm-bootstrap.sh
" 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)] $line"
    echo "$line" >> /tmp/core-bootstrap.log
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Bootstrap log saved to: /tmp/core-bootstrap.log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo -e "${GREEN}✓ Bootstrap complete!${NC}"
echo ""

