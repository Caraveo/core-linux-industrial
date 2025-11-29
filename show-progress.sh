#!/bin/bash
#
# Show build progress with time estimates
#

VM_NAME="core-build"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CORE Linux Build Progress Monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check what's running
echo "Current build processes:"
limactl shell "$VM_NAME" -- bash -c "ps aux | grep -E 'bootstrap|build-core|make|gcc|lb build' | grep -v grep" || echo "No active build processes"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Build Stage Detection:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for kernel build
if limactl shell "$VM_NAME" -- bash -c "test -d /opt/core-build/kernel/linux" 2>/dev/null; then
    if limactl shell "$VM_NAME" -- bash -c "test -f /opt/core-build/kernel/linux/vmlinux" 2>/dev/null; then
        echo "✓ Kernel build: COMPLETE"
    else
        echo "⏳ Kernel build: IN PROGRESS (30-60 min)"
    fi
else
    echo "⏳ Kernel build: Not started"
fi

# Check for ISO build
if limactl shell "$VM_NAME" -- bash -c "test -d /opt/core-build/work/core-live" 2>/dev/null; then
    if limactl shell "$VM_NAME" -- bash -c "test -f /opt/core-build/output/core-industrial-1.0-amd64.iso" 2>/dev/null; then
        echo "✓ ISO build: COMPLETE"
    else
        echo "⏳ ISO build: IN PROGRESS (1-2 hours)"
    fi
else
    echo "⏳ ISO build: Not started"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recent Log Output (last 10 lines):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show recent log
if [[ -f /tmp/core-build.log ]]; then
    tail -10 /tmp/core-build.log
elif limactl shell "$VM_NAME" -- bash -c "test -f /opt/core-build/output/build.log" 2>/dev/null; then
    limactl shell "$VM_NAME" -- bash -c "tail -10 /opt/core-build/output/build.log"
else
    echo "No build log yet - build may not have started"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Time Estimates Remaining:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bootstrap: 10-15 minutes"
echo "  Kernel: 30-60 minutes"
echo "  Modules: 10-20 minutes"
echo "  ISO: 1-2 hours"
echo "  Total: 2-4 hours"
echo ""
echo "The build is working - be patient! Check back in a few minutes."
echo ""

