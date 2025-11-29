# CORE Linux - Quick Start Guide

## TL;DR - Build CORE Linux in 4 Steps

### 1. macOS Host Setup (5 minutes)

```bash
cd /path/to/CORE
./host/setup-host.sh
```

### 2. Create ARM64 Ubuntu VM

- Open UTM or Parallels Desktop
- Create VM from `vm/ubuntu-22.04-server-cloudimg-arm64.img`
- Allocate 8GB+ RAM, 50GB+ disk
- Start VM

### 3. Bootstrap VM (10 minutes)

Inside VM:
```bash
sudo ./vm-bootstrap.sh
```

### 4. Build ISO (2-4 hours)

Inside VM:
```bash
sudo ./build-core.sh
```

Output: `/opt/core-build/output/core-industrial-1.0-amd64.iso`

---

## Detailed Steps

### Prerequisites Check

**macOS Host:**
- [ ] macOS with Apple Silicon (M4)
- [ ] 16GB+ RAM available
- [ ] 100GB+ free disk space
- [ ] UTM or Parallels Desktop installed
- [ ] Internet connection

### Step-by-Step

#### Step 1: Prepare macOS Host

```bash
# Navigate to project
cd /Users/caraveo/CORE

# Run setup (installs Homebrew, downloads Ubuntu image)
./host/setup-host.sh
```

**What it does:**
- Installs Homebrew if missing
- Downloads Ubuntu 22.04 ARM64 cloud image
- Creates project directories
- Verifies UTM/Parallels installation

**Expected output:**
```
✓ Homebrew already installed
✓ UTM detected
✓ Ubuntu image downloaded
Setup Complete!
```

#### Step 2: Create VM

**Using UTM:**
1. Open UTM
2. Click "Create a New Virtual Machine"
3. Select "Linux" → "Use existing disk image"
4. Browse to: `vm/ubuntu-22.04-server-cloudimg-arm64.img`
5. Configure:
   - Memory: 8GB minimum (16GB recommended)
   - Disk: 50GB minimum
6. Start VM

**Using Parallels:**
1. Open Parallels Desktop
2. File → New → From Image
3. Select Ubuntu image
4. Configure resources (8GB+ RAM, 50GB+ disk)
5. Start VM

#### Step 3: Bootstrap VM

**Copy files into VM:**
- Use shared folders, or
- SCP: `scp vm/vm-bootstrap.sh user@vm-ip:~`
- Or copy-paste script content

**Inside VM:**
```bash
# Make executable
chmod +x vm-bootstrap.sh

# Run as root
sudo ./vm-bootstrap.sh
```

**What it does:**
- Updates package lists
- Installs build tools (gcc, make, etc.)
- Installs cross-compilation toolchain (x86_64-linux-gnu-*)
- Installs live-build and ISO tools
- Creates build directories

**Expected output:**
```
✓ Build directories created
✓ x86_64-linux-gnu-gcc installed
Bootstrap Complete!
```

#### Step 4: Build ISO

**Copy files into VM:**
- `build/build-core.sh`
- `branding/` directory (entire folder)

**Inside VM:**
```bash
# Make executable
chmod +x build-core.sh

# Run build (takes 2-4 hours)
sudo ./build-core.sh
```

**What it does:**
1. Clones Linux kernel (v6.1)
2. Configures kernel with CORE_Industrial branding
3. Builds kernel for x86_64
4. Sets up live-build configuration
5. Builds complete ISO image

**Monitor progress:**
- Watch console output
- Check log: `tail -f /opt/core-build/output/build.log`

**Expected output:**
```
✓ Kernel build complete
✓ Live-build configuration complete
✓ ISO created: core-industrial-1.0-amd64.iso
✓ Checksum created: core-industrial-1.0-amd64.iso.sha256
Build Complete!
```

## Verify Build

```bash
# Check ISO exists
ls -lh /opt/core-build/output/

# Verify checksum
cd /opt/core-build/output
sha256sum -c core-industrial-1.0-amd64.iso.sha256
```

## Copy ISO to macOS

**Using shared folders:**
- ISO is in `/opt/core-build/output/`
- Copy to shared folder location

**Using SCP:**
```bash
# From macOS
scp user@vm-ip:/opt/core-build/output/core-industrial-1.0-amd64.iso ./
```

## Test ISO

1. Create new VM in UTM/Parallels
2. Boot from ISO
3. Test installation
4. Verify branding and functionality

## Troubleshooting

### "Command not found" errors
- Re-run bootstrap script
- Check PATH: `echo $PATH`
- Verify packages: `dpkg -l | grep gcc-x86-64`

### Build fails with "out of memory"
- Increase VM RAM to 16GB
- Reduce parallel jobs: Edit `build-core.sh`, change `-j$(nproc)` to `-j2`

### ISO build hangs
- Check internet connection
- Verify Debian mirrors are accessible
- Review build log for errors

### Kernel build fails
- Ensure 10GB+ free disk space
- Check cross-compiler: `x86_64-linux-gnu-gcc --version`
- Clean and retry: `cd /opt/core-build/kernel/linux && make distclean`

## Next Steps

After successful build:

1. **Test ISO** in VM
2. **Create bootable USB** for physical hardware
3. **Customize** branding or packages as needed
4. **Document** any custom configurations

## Support

- Full documentation: See `README.md`
- Build logs: `/opt/core-build/output/build.log`
- Kernel config: `/opt/core-build/kernel/linux/.config`

---

**Ready to build? Start with Step 1!**

