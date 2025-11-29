# 🚀 START HERE - Build CORE Linux Now!

## ✅ Prerequisites Check: ALL READY!

- ✓ Ubuntu image downloaded (640MB)
- ✓ UTM installed
- ✓ All scripts ready and executable

## 📋 Action Plan (5 Steps)

### STEP 1: Create VM (5 minutes)

**Open UTM and create VM:**
1. Open **UTM** app
2. Click **"Create a New Virtual Machine"**
3. Select **"Linux"**
4. Choose **"Use an existing disk image"**
5. Browse and select: `/Users/caraveo/CORE/vm/ubuntu-22.04-server-cloudimg-arm64.img`
6. Configure:
   - **Memory**: 16GB (8GB minimum)
   - **Disk**: 50GB minimum
   - **Shared Folder**: Add `/Users/caraveo/CORE` (for easy file access)
7. Click **"Save"** and **"Start"** the VM

### STEP 2: Login to VM

- Default user: `ubuntu` (or check Ubuntu cloud image docs)
- Password: May need to set via cloud-init or use SSH keys

### STEP 3: Bootstrap VM (10-15 minutes)

**Inside the VM terminal, run:**

```bash
# If shared folder is mounted at /mnt/Shared or similar:
cd /mnt/Shared/CORE
sudo ./vm/vm-bootstrap.sh

# OR if you need to find the shared folder:
ls /mnt/
# Look for your shared folder, then:
cd /path/to/shared/CORE
sudo ./vm/vm-bootstrap.sh
```

**What this does:**
- Installs all build tools
- Sets up cross-compilation toolchain (x86_64)
- Prepares build environment

### STEP 4: Build ISO (2-4 hours) ⏰

**After bootstrap completes, run:**

```bash
# Still in the VM, from the CORE directory:
sudo ./build/build-core.sh
```

**Monitor progress:**
```bash
# In another terminal (or use screen/tmux):
tail -f /opt/core-build/output/build.log
```

**This will:**
- Clone Linux kernel source
- Build custom CORE_Industrial kernel
- Create live-build configuration
- Generate ISO image

### STEP 5: Get Your ISO

**After build completes:**

```bash
# Check the output:
ls -lh /opt/core-build/output/

# Verify checksum:
cd /opt/core-build/output
sha256sum -c core-industrial-1.0-amd64.iso.sha256
```

**Copy to macOS:**
- If using shared folder: ISO is already accessible
- Or use SCP: `scp user@vm-ip:/opt/core-build/output/core-industrial-1.0-amd64.iso ./`

## 🎯 Quick Commands Reference

```bash
# Bootstrap (run once)
sudo ./vm/vm-bootstrap.sh

# Build ISO (takes hours)
sudo ./build/build-core.sh

# Monitor build
tail -f /opt/core-build/output/build.log

# Check results
ls -lh /opt/core-build/output/
```

## ⚠️ Important Notes

1. **Build time**: 2-4 hours (kernel compilation is slow)
2. **Disk space**: Ensure VM has 50GB+ free
3. **Memory**: 16GB recommended for faster builds
4. **Internet**: Required for downloading packages

## 🆘 Troubleshooting

**VM won't start?**
- Check UTM is properly installed
- Verify image file exists: `ls -lh vm/ubuntu-22.04-server-cloudimg-arm64.img`

**Can't find shared folder?**
- Check UTM VM settings → Sharing
- Look in `/mnt/` or `/media/` directories
- Or use SCP to copy files manually

**Build fails?**
- Check disk space: `df -h`
- Check memory: `free -h`
- Review build log: `cat /opt/core-build/output/build.log`

## 📞 Need Help?

- Full docs: `README.md`
- Quick guide: `QUICKSTART.md`
- Run build checker: `./BUILD_NOW.sh`

---

**Ready? Start with STEP 1 - Create your VM!** 🚀

