#!/bin/bash
#
# Watch build progress in real-time
#

VM_NAME="core-build"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CORE Linux Build Monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Watching build progress..."
echo "Press Ctrl+C to stop watching"
echo ""

# Watch multiple log sources
(
    # Local log
    tail -f /tmp/core-build.log 2>/dev/null &
    # VM build log
    limactl shell "$VM_NAME" -- tail -f /opt/core-build/output/build.log 2>/dev/null &
    # VM bootstrap log
    tail -f /tmp/core-bootstrap.log 2>/dev/null &
    wait
) 2>/dev/null || {
    # Fallback: just show VM process status
    while true; do
        clear
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "CORE Linux Build Status - $(date)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Build processes in VM:"
        limactl shell "$VM_NAME" -- bash -c "ps aux | grep -E 'bootstrap|build-core|make|gcc' | grep -v grep" 2>/dev/null || echo "No active build processes"
        echo ""
        echo "Recent build log (last 20 lines):"
        limactl shell "$VM_NAME" -- bash -c "tail -20 /opt/core-build/output/build.log 2>/dev/null || echo 'No build log yet'" 2>/dev/null
        echo ""
        echo "Press Ctrl+C to exit"
        sleep 5
    done
}

