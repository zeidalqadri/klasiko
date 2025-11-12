# Klasiko Build Instructions

This guide explains how to build the Klasiko PDF Converter from source and create distributable packages for macOS.

## Prerequisites

- **macOS**: 10.13 or later
- **Python**: 3.12 or later
- **Homebrew**: For installing system dependencies
- **Xcode Command Line Tools**: For building native extensions

### System Dependencies

Install required system libraries via Homebrew:

```bash
brew install python@3.14
brew install cairo pango gdk-pixbuf libffi
```

## Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd klasiko
```

### 2. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Python Dependencies

```bash
./venv/bin/pip install -r requirements.txt
```

**Note**: The `requirements.txt` includes all runtime dependencies (markdown, weasyprint, Pygments). PyInstaller is commented out since it's only needed for packaging.

### 4. Install PyInstaller (For Packaging Only)

```bash
./venv/bin/pip install pyinstaller
```

## Building the Application

### Building the macOS .app Bundle

The build script automates the entire process:

```bash
./packaging/macos/build-mac.sh
```

This script will:
1. Clean previous builds (`build/`, `dist/`)
2. Activate the virtual environment
3. Verify PyInstaller installation
4. Build `Klasiko.app` using PyInstaller
5. Verify the build and test basic functionality

**Build Output:**
- Location: `dist/Klasiko.app`
- Size: ~57MB
- Architecture: ARM64 (Apple Silicon) or x86_64 (Intel) depending on your Python installation

**Build Time:** ~40-60 seconds

### Build Configuration

The build is configured in `klasiko-macos.spec`:

- **Entry Point**: `klasiko.py`
- **Target Architecture**: Native (ARM64 or x86_64, based on Python)
- **Bundle Identifier**: `com.klasiko.pdfconverter`
- **Version**: 2.1.0
- **Dependencies Bundled**:
  - WeasyPrint (PDF generation)
  - Markdown (content processing)
  - Pygments (code highlighting)
  - All required system libraries (Cairo, Pango, etc.)
  - Shell libraries (`lib/terminal-ui.sh`, `lib/dialogs.sh`)

### Universal Binary (Intel + Apple Silicon)

**Note**: Creating a universal binary requires a universal Python installation. The Homebrew Python is typically single-architecture (ARM64 on Apple Silicon, x86_64 on Intel).

To build for both architectures:
1. Build on an Intel Mac → x86_64 binary
2. Build on Apple Silicon Mac → ARM64 binary
3. Combine with `lipo` (advanced)

Or use Python from python.org which provides universal binaries.

## Creating the DMG Installer

After building the app, create a distributable DMG:

```bash
./packaging/macos/create-dmg.sh
```

This script will:
1. Verify `Klasiko.app` exists
2. Create a staging directory with app + Applications symlink
3. Generate a compressed DMG image
4. Test mounting the DMG
5. Verify the app is accessible in the DMG

**DMG Output:**
- Location: `dist/Klasiko-2.1.0-macOS.dmg`
- Size: ~27MB (compressed from 57MB)
- Volume Name: "Klasiko PDF Converter"

**DMG Creation Time:** ~30-60 seconds

## Complete Build Workflow

To build everything from scratch:

```bash
# 1. Setup environment (first time only)
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
./venv/bin/pip install pyinstaller

# 2. Build the app
./packaging/macos/build-mac.sh

# 3. Create DMG installer
./packaging/macos/create-dmg.sh

# 4. Result: dist/Klasiko-2.1.0-macOS.dmg ready for distribution!
```

## Troubleshooting

### Universal Binary Error

**Error**: `IncompatibleBinaryArchError: ... is not a fat binary!`

**Cause**: Python installation is single-architecture, but spec file requests universal binary.

**Solution**: The spec file is configured for native architecture. If you need universal binary, install universal Python or build on both architectures separately.

### Missing System Libraries

**Error**: `Library not loaded: @rpath/libcairo.2.dylib`

**Cause**: System dependencies not installed.

**Solution**:
```bash
brew install cairo pango gdk-pixbuf libffi
```

### PyInstaller Not Found

**Error**: `pyinstaller: command not found`

**Cause**: PyInstaller not installed in virtual environment.

**Solution**:
```bash
./venv/bin/pip install pyinstaller
```

### Build Cache Issues

If the build behaves unexpectedly, clear the build cache:

```bash
rm -rf build/ dist/ *.spec
./packaging/macos/build-mac.sh
```

## Testing the Build

### Test Command Line Interface

```bash
dist/Klasiko.app/Contents/MacOS/klasiko --help
dist/Klasiko.app/Contents/MacOS/klasiko test.md --theme warm
```

### Test After Installation

```bash
# Install to /Applications
cp -R dist/Klasiko.app /Applications/

# Test from installed location
/Applications/Klasiko.app/Contents/MacOS/klasiko test.md
```

## File Structure

```
klasiko/
├── klasiko.py                          # Main application
├── klasiko-macos.spec                  # PyInstaller configuration
├── requirements.txt                    # Python dependencies
├── lib/
│   ├── terminal-ui.sh                 # Terminal UI library
│   └── dialogs.sh                     # Dialog library
├── packaging/
│   └── macos/
│       ├── build-mac.sh               # Build automation script
│       └── create-dmg.sh              # DMG creation script
├── dist/
│   ├── Klasiko.app                    # Built application
│   └── Klasiko-2.1.0-macOS.dmg       # DMG installer
└── build/                             # Build artifacts (temporary)
```

## Next Steps

After building:

1. **Test the app**: `open dist/Klasiko.app`
2. **Install**: Drag `Klasiko.app` to `/Applications`
3. **Distribute**: Share `dist/Klasiko-2.1.0-macOS.dmg`
4. **Update Quick Actions**: If you have Quick Action workflows installed, they will automatically use the app from `/Applications`

For installation instructions, see [INSTALL.md](INSTALL.md).

For usage documentation, see [README.md](README.md).
