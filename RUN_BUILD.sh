#!/bin/bash
#
# CORE Linux - Run Build (Native ARM64)
# Wrapper to ensure everything runs natively
#

# Force native ARM64 execution
exec arch -arm64 bash << 'EOF'
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Running in native ARM64 mode..."
echo "Architecture: $(uname -m)"
echo ""

# Run the build script
./build-all.sh "$@"
EOF

