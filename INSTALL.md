# Klasiko Installation Guide

This guide explains how to install and set up the Klasiko PDF Converter on macOS.

## Quick Installation (DMG)

### 1. Download

Download the latest release:
- **File**: `Klasiko-2.1.0-macOS.dmg`
- **Size**: ~27MB
- **Requirements**: macOS 10.13 or later

### 2. Install

1. **Double-click** `Klasiko-2.1.0-macOS.dmg` to mount it
2. **Drag** `Klasiko.app` to the `Applications` folder
3. **Eject** the DMG

### 3. First Launch

When you first run Klasiko, macOS may show a security warning because the app is not code-signed:

**Method 1 - System Settings:**
1. Right-click `Klasiko.app` in Applications
2. Select "Open"
3. Click "Open" in the security dialog

**Method 2 - Security & Privacy:**
1. Try to open Klasiko normally
2. Go to **System Settings** → **Privacy & Security**
3. Click **"Open Anyway"** next to the Klasiko security message
4. Click **"Open"** in the confirmation dialog

You only need to do this once. After that, Klasiko will open normally.

## Command Line Usage

Once installed, you can use Klasiko from the command line:

```bash
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md
```

### Create a Global Command (Optional)

To use `klasiko` from anywhere in Terminal:

```bash
# Create symlink in /usr/local/bin
sudo ln -s /Applications/Klasiko.app/Contents/MacOS/klasiko /usr/local/bin/klasiko

# Now you can use it anywhere:
klasiko document.md --theme warm
```

## Quick Actions (Finder Integration)

Klasiko includes macOS Quick Actions that let you convert Markdown files directly from Finder.

### Installing Quick Actions

1. Navigate to the Klasiko source folder
2. Locate the Quick Action scripts:
   - `quick-action-interactive.sh` (recommended)
   - `quick-action-with-visible-progress.sh`
   - `quick-action-script.sh`

3. Follow the setup guide in `QUICK-ACTION-INTERACTIVE-SETUP.md`

### Using Quick Actions

After installation:

1. **Right-click** a Markdown file in Finder
2. Go to **Quick Actions**
3. Select **"MD to PDF - Klasiko!"**
4. Choose your theme and options
5. PDF appears next to your Markdown file

## Verifying Installation

### Test Command Line

```bash
# Check version and help
/Applications/Klasiko.app/Contents/MacOS/klasiko --help

# Test conversion
echo "# Test Document

This is a test." > ~/Desktop/test.md

/Applications/Klasiko.app/Contents/MacOS/klasiko ~/Desktop/test.md --theme warm

# Check output
open ~/Desktop/test.pdf
```

### Check Installed Files

```bash
# Verify app is installed
ls -la /Applications/Klasiko.app

# Check executable
file /Applications/Klasiko.app/Contents/MacOS/klasiko

# Expected output: Mach-O 64-bit executable arm64 (or x86_64)
```

## Usage Examples

### Basic Conversion

```bash
# Default theme
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md

# Specific theme
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md --theme warm

# With table of contents
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md --theme rustic --toc
```

### Logo Branding

```bash
# Logo on title page
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md \
  --logo company-logo.png \
  --logo-placement "title:large"

# Multiple logo placements
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md \
  --logo brand.svg \
  --logo-placement "title:large" \
  --logo-placement "header:small" \
  --theme warm
```

### Advanced Options

```bash
# Custom output location
/Applications/Klasiko.app/Contents/MacOS/klasiko input.md -o ~/Documents/output.pdf

# With metadata
/Applications/Klasiko.app/Contents/MacOS/klasiko report.md \
  --author "Your Name" \
  --subject "Quarterly Report" \
  --keywords "business, report, Q4"
```

## Uninstallation

To remove Klasiko:

```bash
# Remove application
rm -rf /Applications/Klasiko.app

# Remove global command (if created)
sudo rm /usr/local/bin/klasiko

# Remove Quick Actions (if installed)
rm -rf ~/Library/Services/"MD to PDF - klasiko!.workflow"
```

## Troubleshooting

### App Won't Open

**Issue**: "Klasiko.app is damaged and can't be opened"

**Cause**: Gatekeeper blocking unsigned app

**Solution**:
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /Applications/Klasiko.app
```

Then try opening again.

### Command Not Found

**Issue**: `klasiko: command not found`

**Cause**: Symlink not created or `/usr/local/bin` not in PATH

**Solution**:
```bash
# Use full path
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md

# Or create symlink
sudo ln -s /Applications/Klasiko.app/Contents/MacOS/klasiko /usr/local/bin/klasiko
```

### Conversion Fails

**Issue**: PDF not generated

**Check**:
1. Input file is valid Markdown (`.md` extension)
2. Output directory is writable
3. Check Console.app for error messages

**Get detailed output**:
```bash
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md 2>&1 | tee output.log
```

### Quick Actions Not Working

**Issue**: Quick Action doesn't appear or fails

**Cause**: Klasiko.app not installed to `/Applications`

**Solution**:
1. Ensure Klasiko.app is in `/Applications` (not `~/Applications`)
2. Test manually:
   ```bash
   /Applications/Klasiko.app/Contents/MacOS/klasiko test.md
   ```
3. If it works, reinstall the Quick Action

## System Requirements

### Minimum Requirements

- **OS**: macOS 10.13 (High Sierra) or later
- **Architecture**: ARM64 (Apple Silicon) or x86_64 (Intel)
- **Disk Space**: 100MB free space
- **RAM**: 512MB available

### Recommended

- **OS**: macOS 11.0 (Big Sur) or later
- **Disk Space**: 200MB free space
- **RAM**: 1GB available

## Getting Help

### Documentation

- [README.md](README.md) - Feature overview and basic usage
- [BUILD.md](BUILD.md) - Building from source
- [THEME-GUIDE.md](THEME-GUIDE.md) - Visual theme comparison
- [CHANGELOG-v2.1.md](CHANGELOG-v2.1.md) - Version history

### Common Questions

**Q: Do I need Python installed?**
A: No! The packaged app includes everything needed.

**Q: Can I use this on Intel Mac?**
A: Yes, if the build includes x86_64 support. Check with:
```bash
file /Applications/Klasiko.app/Contents/MacOS/klasiko
```

**Q: How do I update?**
A: Download the new DMG and drag to Applications to replace.

**Q: Is internet required?**
A: No, Klasiko works completely offline.

## Security & Privacy

- **Code Signing**: Not signed (free distribution)
- **Network**: No network access required or used
- **Permissions**: Reads Markdown files, writes PDF files
- **Privacy**: No data collection or telemetry

## Support

For issues or questions:
1. Check this documentation
2. Review error messages in Console.app
3. Check GitHub issues (if open source)
4. Create a new issue with details

---

**Installation complete!** 🎉

Start converting: `/Applications/Klasiko.app/Contents/MacOS/klasiko --help`
