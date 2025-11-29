#!/bin/bash
#
# CORE Linux - Complete Automation Script
# Runs all setup steps automatically
#

set -euo pipefail

RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   C O M P L E T E   A U T O${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This script will:"
echo "  1. Setup macOS host"
echo "  2. Initialize git repository"
echo "  3. Setup GitHub repository (optional)"
echo ""

# Step 1: Host setup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: macOS Host Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/host/setup-host.sh"

# Step 2: Git setup
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Git Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "feat: Complete CORE Linux Industrial Edition build system

- Add macOS host setup automation (setup-host.sh)
- Add ARM64 Ubuntu VM bootstrap script (vm-bootstrap.sh)
- Add ISO builder with custom kernel compilation (build-core.sh)
- Add industrial branding assets (GRUB theme, ASCII art)
- Add comprehensive documentation (README.md, QUICKSTART.md)
- Configure x86_64 cross-compilation from ARM64
- Include custom CORE_Industrial kernel build
- Add text-based installer with whiptail
- All scripts executable and ready for production use

Project: CORE Linux - Industrial Edition v1.0
Target: x86_64 architecture
Build: macOS M4 → ARM64 Ubuntu VM → x86_64 ISO"
    echo "✓ Git repository initialized and committed"
else
    echo "Git repository already exists"
    git status
fi

# Step 3: GitHub setup (optional)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: GitHub Repository Setup (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    read -p "Push to GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x "$SCRIPT_DIR/setup-github.sh"
        "$SCRIPT_DIR/setup-github.sh"
    else
        echo "Skipping GitHub setup"
    fi
else
    echo "GitHub CLI not configured. To setup later, run:"
    echo "  ./setup-github.sh"
fi

# Final summary
echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}Automation Complete!${NC}                            ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next Steps:"
echo "  1. Create ARM64 Ubuntu VM using:"
echo "     $SCRIPT_DIR/vm/ubuntu-22.04-server-cloudimg-arm64.img"
echo ""
echo "  2. Inside VM, run:"
echo "     sudo ./vm-bootstrap.sh"
echo ""
echo "  3. Then build ISO:"
echo "     sudo ./build-core.sh"
echo ""
echo "All scripts are ready and executable!"
echo ""

