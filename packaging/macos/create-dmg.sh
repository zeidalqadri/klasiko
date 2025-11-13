#!/bin/bash

# Klasiko DMG Creation Script
# Creates a distributable DMG installer for macOS
#
# Usage: ./packaging/macos/create-dmg.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              KLASIKO DMG INSTALLER CREATION               ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

cd "$PROJECT_ROOT"

# Configuration
APP_NAME="Klasiko"
APP_PATH="dist/Klasiko.app"
DMG_NAME="Klasiko-2.2.1-macOS"
DMG_PATH="dist/${DMG_NAME}.dmg"
VOLUME_NAME="Klasiko PDF Converter"
TMP_DMG_PATH="dist/tmp_${DMG_NAME}.dmg"
ICON_FILE="packaging/macos/klasiko.icns"

# Step 1: Verify app exists
echo -e "${YELLOW}[1/7]${NC} Verifying Klasiko.app..."
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: $APP_PATH not found${NC}"
    echo "Please run ./packaging/macos/build-mac.sh first"
    exit 1
fi
echo "  ✓ Found Klasiko.app"
echo ""

# Step 2: Clean previous DMG
echo -e "${YELLOW}[2/7]${NC} Cleaning previous DMG files..."
if [ -f "$DMG_PATH" ]; then
    rm -f "$DMG_PATH"
    echo "  ✓ Removed old DMG"
fi
if [ -f "$TMP_DMG_PATH" ]; then
    rm -f "$TMP_DMG_PATH"
    echo "  ✓ Removed temporary DMG"
fi
echo ""

# Step 3: Create temporary DMG staging directory
echo -e "${YELLOW}[3/7]${NC} Creating DMG staging area..."
STAGING_DIR="dist/dmg_staging"
if [ -d "$STAGING_DIR" ]; then
    rm -rf "$STAGING_DIR"
fi
mkdir -p "$STAGING_DIR"
echo "  ✓ Created staging directory"

# Copy app to staging
echo "  → Copying Klasiko.app..."
cp -R "$APP_PATH" "$STAGING_DIR/"
echo "  ✓ Copied application"

# Create Applications symlink
echo "  → Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"
echo "  ✓ Created symlink"
echo ""

# Step 4: Calculate required DMG size
echo -e "${YELLOW}[4/7]${NC} Calculating DMG size..."
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
# Add 50MB buffer for filesystem overhead
DMG_SIZE=$((APP_SIZE + 50))
echo "  ✓ App size: ${APP_SIZE}MB"
echo "  ✓ DMG size: ${DMG_SIZE}MB"
echo ""

# Step 5: Create DMG
echo -e "${YELLOW}[5/7]${NC} Creating DMG image..."
echo "  → This may take a minute..."

# Create the DMG with proper settings
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    -size ${DMG_SIZE}m \
    "$DMG_PATH" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ DMG created successfully${NC}"
else
    echo -e "${RED}  ✗ DMG creation failed${NC}"
    rm -rf "$STAGING_DIR"
    exit 1
fi
echo ""

# Step 6: Cleanup and verification
echo -e "${YELLOW}[6/7]${NC} Finalizing..."
rm -rf "$STAGING_DIR"
echo "  ✓ Cleaned up staging directory"

# Verify DMG
if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}  ✗ DMG file not found${NC}"
    exit 1
fi

DMG_SIZE_READABLE=$(du -sh "$DMG_PATH" | cut -f1)
echo "  ✓ DMG size: $DMG_SIZE_READABLE"

# Note: Volume icon would require converting DMG to read-write, applying icon, then converting back
# This adds complexity and the icon is cosmetic only. Skipping for simplicity.
# The app icon will be visible when users open the .app file.

# Test mounting DMG
echo ""
echo "Testing DMG mount..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" 2>&1 | grep "/Volumes" | sed 's/.*\(\/Volumes\/.*\)/\1/')
if [ -n "$MOUNT_POINT" ]; then
    echo -e "${GREEN}  ✓ DMG mounts successfully${NC}"
    echo "  ✓ Mount point: $MOUNT_POINT"

    # Verify app is in DMG
    if [ -d "$MOUNT_POINT/Klasiko.app" ]; then
        echo -e "${GREEN}  ✓ Klasiko.app found in DMG${NC}"
    else
        echo -e "${RED}  ✗ Klasiko.app not found in DMG${NC}"
    fi

    # Unmount
    hdiutil detach "$MOUNT_POINT" -quiet
    echo "  ✓ Unmounted DMG"
else
    echo -e "${YELLOW}  ! Warning: Could not mount DMG for verification${NC}"
fi

# Success summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                  DMG CREATION SUCCESSFUL!                 ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "DMG location: ${BLUE}$DMG_PATH${NC}"
echo -e "DMG size:     ${BLUE}$DMG_SIZE_READABLE${NC}"
echo ""
echo "Distribution ready!"
echo ""
echo -e "${GREEN}Installation instructions for users:${NC}"
echo "  1. Download and open the DMG"
echo "  2. Drag Klasiko.app to Applications folder"
echo -e "  3. Open Terminal and run: ${BLUE}xattr -cr /Applications/Klasiko.app${NC}"
echo "  4. Launch Klasiko from Applications folder"
echo ""
echo -e "${YELLOW}Note: Step 3 is required for unsigned apps downloaded from GitHub${NC}"
echo ""
