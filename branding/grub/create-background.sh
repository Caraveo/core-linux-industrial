#!/bin/bash
#
# Create GRUB background image for CORE Linux
# Requires ImageMagick (install with: brew install imagemagick on macOS)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/background.png"

# Colors
RED="#C00000"
GREY="#6A6A6A"
DARK="#1a1a1a"

# Check for ImageMagick
if ! command -v convert >/dev/null 2>&1; then
    echo "Error: ImageMagick not found"
    echo "Install with: brew install imagemagick (macOS) or apt-get install imagemagick (Linux)"
    exit 1
fi

echo "Creating GRUB background image..."

# Create 1920x1080 background with industrial theme
convert -size 1920x1080 xc:"$DARK" \
  -fill "$RED" -draw "rectangle 0,0 1920,120" \
  -fill "$RED" -draw "rectangle 0,960 1920,1080" \
  -fill "$GREY" -font "DejaVu-Sans-Bold" -pointsize 96 \
  -gravity North -annotate +0+10 "CORE" \
  -fill "$GREY" -font "DejaVu-Sans" -pointsize 32 \
  -gravity North -annotate +0+120 "The Kernel of Industry" \
  -fill "$RED" -strokewidth 2 -draw "line 100,200 1820,200" \
  -fill "$RED" -strokewidth 2 -draw "line 100,880 1820,880" \
  "$OUTPUT_FILE"

echo "✓ Background image created: $OUTPUT_FILE"
echo "  Size: 1920x1080"
echo "  Colors: Industrial Red + Steel Grey"

