# Klasiko Distribution Guide

Complete guide for packaging and distributing Klasiko PDF Converter on macOS.

## Overview

Klasiko uses PyInstaller to create standalone macOS application bundles that include all dependencies. The distribution package includes:

- **Klasiko.app**: Standalone application bundle (~57MB)
- **DMG Installer**: Compressed disk image for easy distribution (~27MB)
- **Quick Actions**: Optional Finder integrations

## Distribution Files

### Application Bundle

**File**: `dist/Klasiko.app`
- **Type**: macOS .app bundle
- **Size**: ~57MB
- **Architecture**: ARM64 (Apple Silicon) or x86_64 (Intel)
- **Contents**:
  - Python 3.14 runtime
  - WeasyPrint PDF engine
  - Markdown processor
  - All system libraries (Cairo, Pango, etc.)
  - Shell UI libraries

### DMG Installer

**File**: `dist/Klasiko-2.1.0-macOS.dmg`
- **Type**: Compressed disk image (UDZO)
- **Size**: ~27MB
- **Contents**:
  - Klasiko.app
  - Applications folder symlink
  - Custom volume name: "Klasiko PDF Converter"

## Build Process

### 1. Development Environment

```bash
# Setup
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
./venv/bin/pip install pyinstaller
```

### 2. Build Application

```bash
./packaging/macos/build-mac.sh
```

**Process**:
1. Clean previous builds
2. Activate virtual environment
3. Verify PyInstaller
4. Analyze dependencies
5. Bundle application
6. Create .app bundle
7. Verify and test

**Output**: `dist/Klasiko.app`

### 3. Create DMG

```bash
./packaging/macos/create-dmg.sh
```

**Process**:
1. Verify app exists
2. Create staging directory
3. Copy app and create symlinks
4. Calculate DMG size
5. Create compressed DMG
6. Test mounting
7. Verify contents

**Output**: `dist/Klasiko-2.1.0-macOS.dmg`

## PyInstaller Configuration

**File**: `klasiko-macos.spec`

### Key Settings

```python
# Entry point
Analysis(['klasiko.py'])

# Architecture
target_arch=None  # Native (ARM64 or x86_64)

# Bundle configuration
bundle_identifier='com.klasiko.pdfconverter'
version='2.1.0'
name='Klasiko.app'

# Console application (for terminal progress)
console=True
```

### Data Files

- `weasyprint` - PDF generation data
- `pyphen` - Hyphenation dictionaries
- `tinycss2` - CSS parsing data
- `lib/terminal-ui.sh` - Terminal UI
- `lib/dialogs.sh` - Dialog system

### Hidden Imports

- weasyprint.css
- weasyprint.css.counters
- weasyprint.css.targets
- weasyprint.text
- weasyprint.layout
- html5lib
- cairocffi

## Distribution Checklist

### Pre-Release

- [ ] Update version in `klasiko-macos.spec`
- [ ] Update version in DMG name (`create-dmg.sh`)
- [ ] Test all features with development build
- [ ] Run full test suite
- [ ] Update CHANGELOG

### Build

- [ ] Clean build environment: `rm -rf build/ dist/`
- [ ] Build app: `./packaging/macos/build-mac.sh`
- [ ] Verify app works: `dist/Klasiko.app/Contents/MacOS/klasiko --help`
- [ ] Test PDF conversion
- [ ] Create DMG: `./packaging/macos/create-dmg.sh`
- [ ] Test DMG mounting

### Testing

- [ ] Fresh install from DMG
- [ ] Test command line interface
- [ ] Test Quick Actions (if included)
- [ ] Test on clean macOS install (if possible)
- [ ] Verify file associations
- [ ] Check app info and version

### Release

- [ ] Tag version in git
- [ ] Generate release notes
- [ ] Upload DMG to distribution platform
- [ ] Update documentation
- [ ] Announce release

## Architecture Support

### Current: Native Architecture

- **ARM64 (Apple Silicon)**: If built on M1/M2/M3 Mac
- **x86_64 (Intel)**: If built on Intel Mac

### Universal Binary (Optional)

To create a universal binary supporting both architectures:

**Option 1**: Use universal Python
```bash
# Install from python.org (provides universal binaries)
# Update spec: target_arch='universal2'
```

**Option 2**: Build on both architectures
```bash
# On Intel Mac:
./packaging/macos/build-mac.sh
mv dist/Klasiko.app dist/Klasiko-Intel.app

# On Apple Silicon Mac:
./packaging/macos/build-mac.sh
mv dist/Klasiko.app dist/Klasiko-ARM.app

# Combine with lipo (advanced)
```

## Code Signing (Optional)

For App Store or notarized distribution:

### 1. Get Developer Certificate

- Enroll in Apple Developer Program
- Create Developer ID Application certificate
- Install certificate in Keychain

### 2. Update Spec File

```python
codesign_identity='Developer ID Application: Your Name (TEAM_ID)'
```

### 3. Sign After Build

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  dist/Klasiko.app
```

### 4. Notarize

```bash
# Create zip for notarization
ditto -c -k --keepParent dist/Klasiko.app Klasiko.zip

# Submit for notarization
xcrun notarytool submit Klasiko.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple ticket
xcrun stapler staple dist/Klasiko.app
```

## Quick Actions Distribution

### Files to Include

- `quick-action-interactive.sh`
- `quick-action-with-visible-progress.sh`
- `quick-action-script.sh`
- `lib/dialogs.sh`
- `lib/terminal-ui.sh`
- `QUICK-ACTION-INTERACTIVE-SETUP.md`

### Installation Instructions

Users must:
1. Install Klasiko.app to `/Applications`
2. Follow Quick Action setup guide
3. Grant necessary permissions

## File Sizes

| Item | Size | Notes |
|------|------|-------|
| Source | ~50KB | Python scripts only |
| Dependencies | ~100MB | venv with all packages |
| Built App | ~57MB | Standalone bundle |
| DMG Installer | ~27MB | Compressed |
| Total Distribution | ~27MB | DMG only |

## Distribution Channels

### GitHub Releases (Recommended)

```bash
# Create release
gh release create v2.1.0 \
  dist/Klasiko-2.1.0-macOS.dmg \
  --title "Klasiko v2.1.0" \
  --notes-file RELEASE_NOTES.md
```

### Direct Download

- Host DMG on website
- Provide SHA256 checksum
- Include installation instructions

### Homebrew Cask (Advanced)

```ruby
cask "klasiko" do
  version "2.1.0"
  sha256 "..."

  url "https://github.com/user/klasiko/releases/download/v#{version}/Klasiko-#{version}-macOS.dmg"
  name "Klasiko PDF Converter"
  desc "Markdown to PDF converter"
  homepage "https://..."

  app "Klasiko.app"
end
```

## Troubleshooting Distribution

### DMG Won't Mount

**Issue**: "Resource temporarily unavailable"

**Solution**: Rebuild DMG with different compression

### App Shows as Damaged

**Issue**: Gatekeeper blocking unsigned app

**User Solution**:
```bash
xattr -d com.apple.quarantine /Applications/Klasiko.app
```

**Long-term**: Code sign the app

### Large File Size

**Current**: 27MB DMG

**Optimizations**:
- [x] UDZO compression (already enabled)
- [ ] Strip debug symbols: `strip=True` in spec
- [ ] Exclude unnecessary files
- [ ] Use UPX compression (may cause issues on macOS)

## Version Scheme

**Format**: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features, logo branding system
- **PATCH**: Bug fixes

**Current**: v2.1.0

## Release Notes Template

```markdown
# Klasiko v2.1.0

## What's New

- Multi-position logo branding system
- Three visual themes (Default, Warm, Rustic)
- Interactive Quick Action workflows
- Progress tracking with timing

## Installation

1. Download `Klasiko-2.1.0-macOS.dmg`
2. Open DMG and drag to Applications
3. Right-click → Open (first time only)

## Requirements

- macOS 10.13 or later
- ARM64 (Apple Silicon) or x86_64 (Intel)

## Changes

See [CHANGELOG-v2.1.md](CHANGELOG-v2.1.md)

## Documentation

- [README.md](README.md) - Usage guide
- [INSTALL.md](INSTALL.md) - Installation
- [BUILD.md](BUILD.md) - Building from source
```

## Maintenance

### Regular Updates

- Update dependencies: `./venv/bin/pip install --upgrade -r requirements.txt`
- Rebuild: `./packaging/macos/build-mac.sh`
- Test thoroughly
- Increment version
- Create new DMG

### Security Updates

- Monitor WeasyPrint and Python security advisories
- Update dependencies promptly
- Rebuild and redistribute

## Future Enhancements

### Planned

- [ ] Windows packaging (PyInstaller with Inno Setup)
- [ ] Code signing and notarization
- [ ] Universal binary (ARM64 + x86_64)
- [ ] Auto-update mechanism
- [ ] Homebrew cask formula

### Under Consideration

- [ ] Linux AppImage
- [ ] Custom installer with options
- [ ] Delta updates
- [ ] Sparkle framework integration

---

**Current Distribution**: macOS DMG installer with native architecture support
**Status**: Production ready ✅
