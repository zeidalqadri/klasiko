# Klasiko Windows Packaging

This directory contains all the files needed to build Klasiko for Windows.

## Quick Start

```powershell
# Build executable
.\build-win.ps1

# Create installer (requires Inno Setup)
.\create-installer.ps1
```

## Files

- **`klasiko-windows.spec`** - PyInstaller configuration file
- **`klasiko-installer.iss`** - Inno Setup installer script
- **`klasiko.ico`** - Windows application icon (6 sizes: 16x16 to 256x256)
- **`build-win.ps1`** - Automated build script for executable
- **`create-installer.ps1`** - Automated installer creation script
- **`create-ico.py`** - Utility to convert PNG images to .ico format

## Build Requirements

1. **Python 3.8+** with pip
2. **PyInstaller** (`pip install pyinstaller`)
3. **Inno Setup 6.0+** (for installer creation)
4. **Virtual environment** with dependencies installed

## Build Process

### 1. Build Executable

```powershell
# From project root
.\packaging\windows\build-win.ps1
```

**Output**: `dist\klasiko.exe` (~80-100MB)

The executable bundles:
- Python runtime
- All dependencies (WeasyPrint, Markdown, Pygments)
- GTK3 libraries (Cairo, Pango, GDK-PixBuf)
- Font configurations

### 2. Create Installer

```powershell
# From project root (after building executable)
.\packaging\windows\create-installer.ps1
```

**Output**: `dist\Klasiko-2.1.1-Windows-Setup.exe` (~30-40MB)

The installer includes:
- Executable installation
- Optional PATH integration
- Optional .md file association
- Start Menu shortcuts
- Documentation
- Uninstaller

## Customization

### Change Version Number

Edit both files:

**`klasiko-windows.spec`**:
```python
# No version in spec file, but update comments if needed
```

**`klasiko-installer.iss`**:
```pascal
#define MyAppVersion "2.1.1"  # Change this
```

### Change Publisher/URLs

Edit **`klasiko-installer.iss`**:
```pascal
#define MyAppPublisher "Your Company"
#define MyAppURL "https://yourwebsite.com"
```

### Modify Icon

Replace `klasiko.ico` with your own icon file, or use `create-ico.py`:

```powershell
# Requires Pillow: pip install Pillow
python create-ico.py
```

## Testing

### Test Executable

```powershell
.\dist\klasiko.exe --help
.\dist\klasiko.exe test.md --theme warm --toc
```

### Test Installer

1. Run installer on clean Windows system
2. Verify PATH integration
3. Test file association
4. Check Start Menu shortcuts
5. Test uninstaller

## Troubleshooting

**PyInstaller fails**:
- Ensure virtual environment is activated
- Reinstall dependencies: `pip install -r requirements.txt --force-reinstall`

**Inno Setup not found**:
- Install from https://jrsoftware.org/isdl.php
- Verify default install location: `C:\Program Files (x86)\Inno Setup 6\`

**Executable is too large**:
- This is expected (~80-100MB) due to GTK3 bundling
- Installer compresses it to ~30-40MB

**DLL errors when running**:
- Install Visual C++ Redistributable
- Download: https://aka.ms/vs/17/release/vc_redist.x64.exe

## Distribution

**End users should download**:
- `Klasiko-2.1.1-Windows-Setup.exe` (installer - recommended)
- OR `klasiko.exe` (portable - no installation)

**Generate checksum**:
```powershell
Get-FileHash dist\Klasiko-2.1.1-Windows-Setup.exe -Algorithm SHA256
```

## Technical Details

**Build Time**: ~60 seconds for executable, ~30 seconds for installer

**Build Size**:
- Executable: ~80-100MB (uncompressed)
- Installer: ~30-40MB (compressed)
- Installed: ~200MB

**Architecture**: x64 only (64-bit Windows)

**Compatibility**: Windows 10+, Windows Server 2019+

## Support

For detailed build instructions, see: [WINDOWS-BUILD.md](../../WINDOWS-BUILD.md)

For issues, check the Troubleshooting section in WINDOWS-BUILD.md.
