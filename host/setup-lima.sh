#!/bin/bash
#
# CORE Linux - Lima VM Automation
# Fully automated VM setup using Lima
#

set -euxo pipefail  # -x for verbose command tracing

RED='\033[0;31m'
GREY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_NAME="core-build"

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   L I M A   A U T O M A T I O N${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Lima is installed
if ! command -v limactl >/dev/null 2>&1; then
    echo "Installing Lima..."
    if command -v brew >/dev/null 2>&1; then
        # Use native Homebrew for ARM64
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            /opt/homebrew/bin/brew install lima
        else
            brew install lima
        fi
    else
        echo -e "${RED}Error: Homebrew not found. Please install Lima manually.${NC}"
        echo "Visit: https://github.com/lima-vm/lima"
        exit 1
    fi
fi

# Check if VM already exists
if limactl list | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}VM '$VM_NAME' already exists.${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and deleting existing VM..."
        limactl stop "$VM_NAME" || true
        limactl delete "$VM_NAME" || true
    else
        echo "Using existing VM..."
        limactl start "$VM_NAME" || true
        exit 0
    fi
fi

# Create Lima VM using ubuntu template
echo "Creating Lima VM instance (Ubuntu 22.04 ARM64)..."
echo "This will download the Ubuntu image if needed..."
echo ""

# Use limactl (correct command)
LIMA_CMD="limactl"

# Create Lima VM using ubuntu template
# Lima uses YAML config files, so we'll create one dynamically
LIMA_YAML="/tmp/core-build-lima.yaml"
cat > "$LIMA_YAML" << YAML_EOF
# CORE Linux Build VM
images:
  - location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img"
    arch: "aarch64"

cpus: 4
memory: "16G"
disk: "50G"

mounts:
  - location: "$PROJECT_ROOT"
    writable: true
    mountPoint: "/mnt/CORE"

provision:
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y sudo
YAML_EOF

echo "Creating VM from YAML config..."
$LIMA_CMD create --name="$VM_NAME" "$LIMA_YAML" || {
    echo -e "${RED}Error: Failed to create VM${NC}"
    rm -f "$LIMA_YAML"
    exit 1
}
rm -f "$LIMA_YAML"

# Start VM
echo "Starting VM..."
$LIMA_CMD start "$VM_NAME"

# Wait for VM to be ready
echo "Waiting for VM to be ready..."
sleep 5

# Verify VM is accessible
echo "Verifying VM connectivity..."
$LIMA_CMD shell "$VM_NAME" -- bash -c "echo 'VM is ready'" || {
    echo -e "${YELLOW}Warning: Shell init had errors (this is normal), continuing...${NC}"
}

# Create directories in VM (with sudo for /opt)
echo "Creating build directories in VM..."
$LIMA_CMD shell "$VM_NAME" -- bash -c "sudo mkdir -p /opt/core-build"
VM_USER=$($LIMA_CMD shell "$VM_NAME" -- bash -c "whoami")
VM_GROUP=$($LIMA_CMD shell "$VM_NAME" -- bash -c "id -gn")
$LIMA_CMD shell "$VM_NAME" -- bash -c "sudo chown $VM_USER:$VM_GROUP /opt/core-build"
$LIMA_CMD shell "$VM_NAME" -- bash -c "mkdir -p /tmp/core-build"

echo "✓ Directories created"
$LIMA_CMD shell "$VM_NAME" -- bash -c "ls -ld /opt/core-build /tmp/core-build"

# Copy scripts to VM
echo ""
echo "Copying build scripts to VM..."

# Copy files using lima's built-in copy (if available) or scp
# Copy files - try mounted directory first, then base64
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Transferring files to VM..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for mounted directory
if $LIMA_CMD shell "$VM_NAME" -- bash -c "test -d /mnt/CORE"; then
    echo "✓ Mounted directory found at /mnt/CORE"
    echo "Copying vm-bootstrap.sh..."
    $LIMA_CMD shell "$VM_NAME" -- bash -c "cp -v /mnt/CORE/vm/vm-bootstrap.sh /tmp/vm-bootstrap.sh && chmod +x /tmp/vm-bootstrap.sh && ls -lh /tmp/vm-bootstrap.sh"
    
    echo "Copying build-core.sh..."
    $LIMA_CMD shell "$VM_NAME" -- bash -c "cp -v /mnt/CORE/build/build-core.sh /tmp/build-core.sh && chmod +x /tmp/build-core.sh && ls -lh /tmp/build-core.sh"
    
    echo "Copying branding directory..."
    $LIMA_CMD shell "$VM_NAME" -- bash -c "cp -rv /mnt/CORE/branding /tmp/branding && ls -la /tmp/branding" || echo "⚠ Branding copy may have failed"
else
    echo "⚠ Mounted directory not found, using base64 transfer..."
    echo "Transferring vm-bootstrap.sh via base64..."
    base64 < "$PROJECT_ROOT/vm/vm-bootstrap.sh" | \
        $LIMA_CMD shell "$VM_NAME" -- bash -c "base64 -d > /tmp/vm-bootstrap.sh && chmod +x /tmp/vm-bootstrap.sh && ls -lh /tmp/vm-bootstrap.sh"
    
    echo "Transferring build-core.sh via base64..."
    base64 < "$PROJECT_ROOT/build/build-core.sh" | \
        $LIMA_CMD shell "$VM_NAME" -- bash -c "base64 -d > /tmp/build-core.sh && chmod +x /tmp/build-core.sh && ls -lh /tmp/build-core.sh"
fi

echo ""
echo "Verifying files in VM..."
$LIMA_CMD shell "$VM_NAME" -- bash -c "ls -lh /tmp/vm-bootstrap.sh /tmp/build-core.sh"
$LIMA_CMD shell "$VM_NAME" -- bash -c "test -f /tmp/vm-bootstrap.sh && echo '✓ vm-bootstrap.sh ready' || echo '✗ vm-bootstrap.sh missing'"
$LIMA_CMD shell "$VM_NAME" -- bash -c "test -f /tmp/build-core.sh && echo '✓ build-core.sh ready' || echo '✗ build-core.sh missing'"

# Ensure scripts are executable
$LIMA_CMD shell "$VM_NAME" -- chmod +x /tmp/vm-bootstrap.sh /tmp/build-core.sh || true

echo ""
echo -e "${GREEN}✓ VM created and ready!${NC}"
echo ""
echo "VM is running. You can access it with:"
echo "  limactl shell $VM_NAME"
echo ""
echo "Next steps:"
echo "  1. Run bootstrap: ./host/bootstrap-vm.sh"
echo "  2. Run build: ./host/build-iso.sh"
echo "  Or run everything: ./build-all.sh"
echo ""
