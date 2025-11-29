# CORE Linux GRUB Theme

This directory contains the GRUB theme files for CORE Linux Industrial Edition.

## Files

- `theme.txt` - GRUB theme configuration
- `background.png` - Background image (create a 1920x1080 image with steel grey and red theme)
- `terminal_box_*.png` - Terminal box graphics (optional)

## Color Scheme

- Steel Grey: #6A6A6A
- Industrial Red: #C00000
- Background: #1a1a1a (dark)

## Creating Background Image

You can create a simple background image using ImageMagick:

```bash
convert -size 1920x1080 xc:#1a1a1a \
  -fill "#C00000" -draw "rectangle 0,0 1920,100" \
  -fill "#6A6A6A" -font "DejaVu-Sans-Bold" -pointsize 72 \
  -annotate +960+50 "CORE Linux" \
  background.png
```

Or use any image editor to create a custom industrial-themed background.

