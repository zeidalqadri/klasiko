#!/bin/bash

# Klasiko macOS Build Script
# Builds a universal binary .app bundle for both Intel and Apple Silicon Macs
#
# Usage: ./packaging/macos/build-mac.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}               KLASIKO macOS BUILD - NATIVE                ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

cd "$PROJECT_ROOT"

# Step 1: Clean previous builds
echo -e "${YELLOW}[1/5]${NC} Cleaning previous builds..."
if [ -d "build" ]; then
    rm -rf build
    echo "  ✓ Removed build/"
fi
if [ -d "dist" ]; then
    rm -rf dist
    echo "  ✓ Removed dist/"
fi
if [ -f "klasiko.spec" ]; then
    rm -f klasiko.spec
    echo "  ✓ Removed old klasiko.spec"
fi
echo ""

# Step 2: Activate virtual environment
echo -e "${YELLOW}[2/5]${NC} Activating virtual environment..."
if [ ! -d "venv" ]; then
    echo -e "${RED}Error: Virtual environment not found at venv/${NC}"
    echo "Please run: python3 -m venv venv && ./venv/bin/pip install -r requirements.txt"
    exit 1
fi

source venv/bin/activate
echo "  ✓ Virtual environment activated"
echo ""

# Step 3: Verify PyInstaller is installed
echo -e "${YELLOW}[3/5]${NC} Verifying PyInstaller installation..."
if ! command -v pyinstaller &> /dev/null; then
    echo -e "${RED}Error: PyInstaller not found${NC}"
    echo "Installing PyInstaller..."
    pip install pyinstaller
fi
PYINSTALLER_VERSION=$(pyinstaller --version)
echo "  ✓ PyInstaller $PYINSTALLER_VERSION"
echo ""

# Step 4: Build with PyInstaller
echo -e "${YELLOW}[4/5]${NC} Building Klasiko.app with PyInstaller..."
echo "  → This may take several minutes..."
echo ""

if pyinstaller klasiko-macos.spec; then
    echo ""
    echo -e "${GREEN}  ✓ Build completed successfully${NC}"
else
    echo ""
    echo -e "${RED}  ✗ Build failed${NC}"
    deactivate
    exit 1
fi
echo ""

# Step 5: Verify the build
echo -e "${YELLOW}[5/5]${NC} Verifying build..."

APP_PATH="dist/Klasiko.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}  ✗ Klasiko.app not found at $APP_PATH${NC}"
    deactivate
    exit 1
fi

EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/klasiko"
if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo -e "${RED}  ✗ Executable not found at $EXECUTABLE_PATH${NC}"
    deactivate
    exit 1
fi

# Check architecture
ARCH_INFO=$(file "$EXECUTABLE_PATH")
if echo "$ARCH_INFO" | grep -q "arm64"; then
    echo -e "${GREEN}  ✓ ARM64 binary (Apple Silicon)${NC}"
elif echo "$ARCH_INFO" | grep -q "x86_64"; then
    echo -e "${GREEN}  ✓ x86_64 binary (Intel)${NC}"
elif echo "$ARCH_INFO" | grep -q "universal binary"; then
    echo -e "${GREEN}  ✓ Universal binary (Intel + Apple Silicon)${NC}"
else
    echo -e "${YELLOW}  ! Architecture: $ARCH_INFO${NC}"
fi

# Get app size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo "  ✓ Application size: $APP_SIZE"

# Test basic functionality
echo ""
echo "Testing basic functionality..."
if "$EXECUTABLE_PATH" --help > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Application executable works${NC}"
else
    echo -e "${YELLOW}  ! Warning: Application test failed (may need full environment)${NC}"
fi

# Deactivate virtual environment
deactivate

# Success summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                    BUILD SUCCESSFUL!                       ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Application location: ${BLUE}$APP_PATH${NC}"
echo -e "Application size:     ${BLUE}$APP_SIZE${NC}"
echo ""
echo "Next steps:"
echo "  1. Test the app: open dist/Klasiko.app"
echo "  2. Create DMG installer: ./packaging/macos/create-dmg.sh"
echo "  3. Install to /Applications"
echo ""
