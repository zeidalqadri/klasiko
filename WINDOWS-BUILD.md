# Building Klasiko for Windows

This guide explains how to build Klasiko from source on Windows, creating both the standalone executable and the installer.

## Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Build Process](#build-process)
- [Building the Executable](#building-the-executable)
- [Creating the Installer](#creating-the-installer)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Distribution](#distribution)

## Quick Start

```powershell
# 1. Install prerequisites
python --version  # Should be 3.8+

# 2. Set up development environment
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
pip install pyinstaller

# 3. Build executable
.\packaging\windows\build-win.ps1

# 4. Install Inno Setup from https://jrsoftware.org/isdl.php

# 5. Create installer
.\packaging\windows\create-installer.ps1
```

## Prerequisites

### Required Software

1. **Python 3.8 or higher**
   - Download from: https://www.python.org/downloads/
   - During installation, check "Add Python to PATH"
   - Verify: `python --version`

2. **Inno Setup 6.0+** (for creating installer)
   - Download from: https://jrsoftware.org/isdl.php
   - Install to default location: `C:\Program Files (x86)\Inno Setup 6\`

3. **Git** (optional, for cloning repository)
   - Download from: https://git-scm.com/download/win

### System Requirements

- **OS**: Windows 10 or Windows 11
- **Architecture**: x64 (64-bit)
- **Disk Space**: ~500MB for build artifacts
- **RAM**: 4GB minimum, 8GB recommended

## Build Process

### Step 1: Clone or Download

```powershell
# Option 1: Clone with Git
git clone https://github.com/yourusername/klasiko.git
cd klasiko

# Option 2: Download and extract ZIP from GitHub
```

### Step 2: Set Up Virtual Environment

```powershell
# Create virtual environment
python -m venv venv

# Activate it
.\venv\Scripts\activate

# Verify activation (you should see (venv) in prompt)
```

### Step 3: Install Dependencies

```powershell
# Install runtime dependencies
pip install -r requirements.txt

# Install PyInstaller for building
pip install pyinstaller

# Verify installations
pip list | Select-String "weasyprint|pyinstaller|markdown"
```

**Note**: WeasyPrint on Windows comes with pre-compiled GTK3 binaries. If you encounter issues:
```powershell
# Install GTK3 manually (alternative)
# Download from: https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer
```

## Building the Executable

### Using the Build Script (Recommended)

```powershell
# Run the automated build script
.\packaging\windows\build-win.ps1
```

The script will:
1. ✓ Clean previous builds
2. ✓ Verify virtual environment
3. ✓ Check PyInstaller installation
4. ✓ Build with PyInstaller
5. ✓ Verify the executable
6. ✓ Copy to `dist\klasiko.exe`

**Expected output**: `dist\klasiko.exe` (~80-100MB)

### Manual Build (Advanced)

```powershell
# Change to packaging/windows directory
cd packaging\windows

# Run PyInstaller with spec file
..\..\venv\Scripts\pyinstaller.exe klasiko-windows.spec

# Executable will be in: packaging\windows\dist\klasiko.exe
```

### What Gets Bundled

The PyInstaller build bundles:
- Python interpreter
- All Python dependencies (weasyprint, markdown, pygments)
- GTK3 runtime libraries (Cairo, Pango, GDK-PixBuf)
- Font configuration
- All data files required by dependencies

**Result**: A single standalone `.exe` that works without Python installation.

## Creating the Installer

### Using the Installer Script (Recommended)

```powershell
# Ensure klasiko.exe is built first
.\packaging\windows\create-installer.ps1
```

The script will:
1. ✓ Verify `klasiko.exe` exists
2. ✓ Locate Inno Setup
3. ✓ Prepare files
4. ✓ Clean previous installers
5. ✓ Build installer
6. ✓ Verify output

**Expected output**: `dist\Klasiko-2.1.1-Windows-Setup.exe` (~30-40MB compressed)

### Manual Build with Inno Setup (Advanced)

```powershell
# Locate ISCC (Inno Setup Compiler)
$IsccPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"

# Compile installer script
& $IsccPath packaging\windows\klasiko-installer.iss

# Installer will be in: dist\Klasiko-2.1.1-Windows-Setup.exe
```

### Installer Features

The installer includes:
- **Executable Installation**: Installs `klasiko.exe` to `C:\Program Files\Klasiko\`
- **PATH Integration** (optional): Adds Klasiko to system PATH
- **File Association** (optional): Right-click `.md` files → "Convert to PDF with Klasiko"
- **Start Menu Shortcuts**: Command line and GUI shortcuts
- **Documentation**: README, CHANGELOG, THEME-GUIDE
- **Uninstaller**: Complete uninstall support

### Customizing the Installer

Edit `packaging\windows\klasiko-installer.iss`:

```pascal
; Change version
#define MyAppVersion "2.1.1"

; Change publisher
#define MyAppPublisher "Your Company Name"

; Change URL
#define MyAppURL "https://yourwebsite.com"
```

## Testing

### Test the Executable

```powershell
# Test help command
.\dist\klasiko.exe --help

# Test basic conversion
.\dist\klasiko.exe test.md

# Test with theme
.\dist\klasiko.exe test.md --theme rustic --toc

# Test with logo
.\dist\klasiko.exe test.md --logo logo.png --logo-placement "title:large"
```

### Test the Installer

1. **Install on Clean System**:
   - Run `Klasiko-2.1.1-Windows-Setup.exe`
   - Choose installation options
   - Complete installation

2. **Verify PATH Integration**:
   ```powershell
   # Open NEW PowerShell window
   klasiko --help
   ```

3. **Test File Association**:
   - Right-click a `.md` file
   - Look for "Convert to PDF with Klasiko" option
   - Click it and verify PDF is created

4. **Check Start Menu**:
   - Open Start Menu
   - Search for "Klasiko"
   - Verify shortcuts work

5. **Test Uninstaller**:
   - Settings → Apps → Klasiko PDF Converter → Uninstall
   - Verify clean removal

### Test the GUI

```powershell
# Launch GUI
python klasiko-gui.py

# Or if installed:
klasiko-gui
```

Test GUI features:
- ✓ Browse for input Markdown file
- ✓ Select output location
- ✓ Choose theme
- ✓ Add logo with multiple placements
- ✓ Fill in metadata
- ✓ Convert and verify output
- ✓ Auto-open PDF after conversion

## Troubleshooting

### Build Issues

**Problem**: "PyInstaller not found"
```powershell
# Solution: Install PyInstaller
.\venv\Scripts\pip install pyinstaller
```

**Problem**: "Import Error: cairo"
```powershell
# Solution: Reinstall weasyprint
.\venv\Scripts\pip uninstall weasyprint
.\venv\Scripts\pip install weasyprint --no-cache-dir
```

**Problem**: "Executable too large (>150MB)"
```powershell
# Solution: This is expected for first build
# Subsequent builds may be smaller with UPX compression
# The installer compresses it to ~30-40MB
```

### Runtime Issues

**Problem**: "DLL Load Failed" when running klasiko.exe
```powershell
# Solution: Install Visual C++ Redistributable
# Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
```

**Problem**: "Font not found" errors
```powershell
# Solution: Install standard fonts
# Klasiko uses: Palatino, Garamond, Georgia (Windows includes these)
```

**Problem**: GUI doesn't start
```powershell
# Solution: Tkinter should be included with Python
# If missing, reinstall Python with "tcl/tk" option checked
```

### Installer Issues

**Problem**: "Inno Setup not found"
```powershell
# Solution: Install Inno Setup
# Download: https://jrsoftware.org/isdl.php
# Install to default location
```

**Problem**: "Access Denied" during installation
```powershell
# Solution: Run installer as Administrator
# Right-click → "Run as administrator"
```

## Distribution

### Files to Distribute

**For End Users**:
- `Klasiko-2.1.1-Windows-Setup.exe` - The installer (recommended)

**Alternative (Portable)**:
- `klasiko.exe` - Standalone executable (no installation needed)

### Publishing Options

1. **GitHub Releases**:
   ```powershell
   # Upload to GitHub Releases
   # Tag version: v2.1.1
   # Include: Klasiko-2.1.1-Windows-Setup.exe
   ```

2. **Direct Download**:
   - Host installer on your website
   - Provide SHA256 checksum for verification:
   ```powershell
   Get-FileHash dist\Klasiko-2.1.1-Windows-Setup.exe -Algorithm SHA256
   ```

3. **Company Distribution**:
   - Deploy via Group Policy (use MSI format)
   - Or distribute via internal software portal

### Version Updates

To create a new version:

1. **Update Version Numbers**:
   ```powershell
   # Update in these files:
   # - klasiko.py (if it contains version)
   # - packaging/windows/klasiko-installer.iss (#define MyAppVersion)
   ```

2. **Rebuild**:
   ```powershell
   .\packaging\windows\build-win.ps1
   .\packaging\windows\create-installer.ps1
   ```

3. **Tag Release**:
   ```powershell
   git tag -a v2.1.1 -m "Release version 2.1.1"
   git push origin v2.1.1
   ```

## Build Artifacts

After building, you'll have:

```
klasiko/
├── dist/
│   ├── klasiko.exe                          # Standalone executable
│   └── Klasiko-2.1.1-Windows-Setup.exe     # Installer
├── packaging/
│   └── windows/
│       ├── build/                          # PyInstaller temp files (can delete)
│       ├── dist/
│       │   └── klasiko.exe                 # Built executable
│       ├── klasiko-windows.spec            # PyInstaller config
│       ├── klasiko-installer.iss           # Inno Setup script
│       ├── klasiko.ico                     # Windows icon
│       ├── build-win.ps1                   # Build script
│       └── create-installer.ps1            # Installer script
└── build/                                  # PyInstaller cache (can delete)
```

### Cleaning Build Artifacts

```powershell
# Remove all build artifacts
Remove-Item -Recurse -Force build, dist, packaging\windows\build, packaging\windows\dist

# Keep only source files
```

## Advanced Topics

### Code Signing

To sign the executable and installer:

```powershell
# Get a code signing certificate
# Then sign executable:
signtool sign /f cert.pfx /p password /t http://timestamp.digicert.com dist\klasiko.exe

# Sign installer:
signtool sign /f cert.pfx /p password /t http://timestamp.digicert.com dist\Klasiko-2.1.1-Windows-Setup.exe
```

### Creating MSI Installer

For enterprise deployment, convert Inno Setup to MSI:

```powershell
# Use WiX Toolset instead of Inno Setup
# Or use third-party tools like Advanced Installer
```

### Build Automation

Create a GitHub Action or Azure Pipeline:

```yaml
# .github/workflows/build-windows.yml
name: Build Windows

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      - run: |
          python -m venv venv
          .\venv\Scripts\activate
          pip install -r requirements.txt
          pip install pyinstaller
          .\packaging\windows\build-win.ps1
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/yourusername/klasiko/issues
- Documentation: [README.md](README.md)
- Theme Guide: [THEME-GUIDE.md](THEME-GUIDE.md)

## License

See [LICENSE](LICENSE) file for details.
