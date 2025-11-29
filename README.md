# CORE Linux — Industrial Edition

**The Kernel of Industry**

A custom Linux distribution built for industrial applications, reliability, and performance.

## Overview

CORE Linux Industrial Edition is a Debian-based Linux distribution optimized for x86_64 architecture with a heavy-duty, minimalist aesthetic. Built using cross-compilation from macOS M4 Apple Silicon hosts via ARM64 Ubuntu VMs.

### Brand Identity

- **Name**: CORE Linux — Industrial Edition
- **Color Palette**: Steel Grey (#6A6A6A) + Industrial Red (#C00000)
- **Style**: Heavy-duty, minimalist, "manufacturing machine" aesthetic
- **Hostname**: `core-industrial`
- **Kernel**: Custom `CORE_Industrial` kernel

## Project Structure

```
CORE/
├── host/
│   └── setup-host.sh          # macOS host preparation script
├── vm/
│   └── vm-bootstrap.sh        # ARM64 Ubuntu VM provisioning
├── build/
│   └── build-core.sh          # ISO builder script
├── branding/
│   ├── grub/                  # GRUB theme files
│   │   ├── theme.txt
│   │   └── README.md
│   └── ascii/                 # ASCII art and banners
│       ├── motd
│       ├── issue
│       ├── issue.net
│       └── boot-splash.txt
└── README.md                  # This file
```

## Prerequisites

### macOS Host Requirements

- macOS with Apple Silicon (M4 recommended)
- At least 16GB RAM (32GB recommended for VM)
- At least 100GB free disk space
- UTM or Parallels Desktop installed
- Internet connection for downloads

### VM Requirements

- ARM64 Ubuntu 22.04 LTS
- At least 8GB RAM (16GB recommended)
- At least 50GB disk space
- Internet connection

## Quick Start Guide

### Step 1: Prepare macOS Host

1. Open Terminal and navigate to the project directory:
   ```bash
   cd /path/to/CORE
   ```

2. Run the host setup script:
   ```bash
   chmod +x host/setup-host.sh
   ./host/setup-host.sh
   ```

   This script will:
   - Install Homebrew (if missing)
   - Install required tools
   - Download Ubuntu ARM64 cloud image
   - Create necessary directories

### Step 2: Create ARM64 Ubuntu VM

1. **Using UTM:**
   - Open UTM
   - Click "Create a New Virtual Machine"
   - Select "Linux"
   - Choose "Use an existing disk image"
   - Select the downloaded Ubuntu image from `vm/ubuntu-22.04-server-cloudimg-arm64.img`
   - Allocate at least 8GB RAM and 50GB disk
   - Start the VM

2. **Using Parallels Desktop:**
   - Open Parallels Desktop
   - Create new VM from the Ubuntu image
   - Configure with at least 8GB RAM and 50GB disk
   - Start the VM

### Step 3: Bootstrap the VM

1. Copy `vm/vm-bootstrap.sh` into the VM (via shared folders, SCP, or copy-paste)

2. Inside the VM, run:
   ```bash
   chmod +x vm-bootstrap.sh
   sudo ./vm-bootstrap.sh
   ```

   This installs all required build tools and cross-compilation toolchains.

### Step 4: Build CORE Linux ISO

1. Copy `build/build-core.sh` into the VM

2. Copy the `branding/` directory into the VM (or use shared folders)

3. Inside the VM, run:
   ```bash
   chmod +x build-core.sh
   sudo ./build-core.sh
   ```

   **Note**: This process takes several hours. The script will:
   - Clone and build the Linux kernel with CORE_Industrial branding
   - Configure live-build for ISO creation
   - Build the complete ISO image

4. The output will be in `/opt/core-build/output/`:
   - `core-industrial-1.0-amd64.iso`
   - `core-industrial-1.0-amd64.iso.sha256`

## Build Process Details

### Kernel Customization

The build process creates a custom Linux kernel with:

- **Name**: `CORE_Industrial`
- **Architecture**: x86_64
- **Optimizations**: -O2 flags, optional LTO
- **Enabled Features**:
  - UEFI + legacy BIOS boot support
  - NVMe and SATA storage drivers
  - WiFi support (Intel wireless)
  - Intel iGPU drivers
  - Industrial-grade reliability features

### ISO Contents

The generated ISO includes:

- **Base System**: Debian Bookworm base
- **Essential Tools**: bash, nano, vim, htop, git, ssh
- **Custom Branding**: GRUB theme, login banners, MOTD
- **Installer**: Text-based installer using whiptail
- **Default User**: Non-root user "core" (created during install)
- **Networking**: DHCP auto-configuration, SSH enabled

### Installer Features

The included installer (`core-install`) provides:

- Guided GPT partitioning
- ext4 filesystem
- Optional LUKS encrypted root (future enhancement)
- Automatic user creation
- SSH server setup
- Network configuration

## Branding Assets

### GRUB Theme

Located in `branding/grub/`:

- `theme.txt` - GRUB theme configuration
- Uses industrial red (#C00000) and steel grey (#6A6A6A) color scheme
- Dark background (#1a1a1a) for industrial aesthetic

### ASCII Art

Located in `branding/ascii/`:

- `motd` - Message of the day (displayed after login)
- `issue` - Local login banner
- `issue.net` - SSH login banner
- `boot-splash.txt` - Boot splash screen

All banners feature the CORE Linux ASCII logo and "The Kernel of Industry" tagline.

## Troubleshooting

### Build Failures

**Kernel build fails:**
- Ensure you have at least 8GB RAM allocated to VM
- Check disk space (kernel build requires ~10GB)
- Verify cross-compiler is installed: `x86_64-linux-gnu-gcc --version`

**ISO build fails:**
- Ensure live-build is properly installed
- Check internet connection (needs to download packages)
- Review build log: `/opt/core-build/output/build.log`

**Out of disk space:**
- Clean previous builds: `sudo rm -rf /opt/core-build/work`
- Increase VM disk size
- Free up space on host

### VM Issues

**VM won't start:**
- Verify UTM/Parallels is properly installed
- Check Ubuntu image integrity
- Ensure sufficient host resources

**Network issues in VM:**
- Configure VM network adapter (NAT or Bridged)
- Verify host internet connection
- Check VM firewall settings

### Cross-Compilation Issues

**Compiler not found:**
- Re-run `vm-bootstrap.sh`
- Verify: `dpkg -l | grep gcc-x86-64-linux-gnu`
- Check PATH: `echo $CROSS_COMPILE`

## Advanced Configuration

### Custom Kernel Options

Edit `build/build-core.sh` to modify kernel configuration:

```bash
# Add custom kernel options
./scripts/config --enable CONFIG_YOUR_OPTION
```

### Custom Packages

Edit the package list in `build/build-core.sh`:

```bash
# Modify config/package-lists/core.list.chroot
```

### Build Optimization

For faster builds:

- Use more CPU cores: `-j$(nproc)` (already configured)
- Use local package mirror
- Enable ccache for kernel builds
- Use tmpfs for build directories (if sufficient RAM)

## Output Files

After successful build:

```
/opt/core-build/output/
├── core-industrial-1.0-amd64.iso      # Bootable ISO image
├── core-industrial-1.0-amd64.iso.sha256  # SHA256 checksum
└── build.log                          # Complete build log
```

## Verification

Verify ISO integrity:

```bash
cd /opt/core-build/output
sha256sum -c core-industrial-1.0-amd64.iso.sha256
```

## Testing the ISO

1. Copy ISO from VM to macOS host
2. Create bootable USB or test in VM:
   ```bash
   # Using UTM/Parallels, create new VM from ISO
   # Boot and test installation
   ```

## Support and Documentation

- **Documentation**: https://core-linux.org/docs
- **Support**: https://core-linux.org/support
- **Bug Reports**: https://core-linux.org/bugs

## License

CORE Linux Industrial Edition is built on Debian and follows Debian's licensing terms. Custom components are provided as-is for industrial use.

## Version History

- **v1.0** - Initial release
  - Custom CORE_Industrial kernel
  - Industrial branding and themes
  - Text-based installer
  - x86_64 architecture support

## Contributing

This is an automated build system. To contribute:

1. Modify scripts in respective directories
2. Update branding assets as needed
3. Test builds thoroughly
4. Document changes

## Acknowledgments

- Built on Debian Linux
- Uses Linux kernel from kernel.org
- GRUB bootloader
- live-build tools

---

**CORE Linux — The Kernel of Industry**

