#!/bin/bash
#
# Klasiko macOS Installation Script
# Automated installer that handles quarantine removal and system integration
#
# Usage:
#   1. Download this script and Klasiko DMG to the same folder
#   2. Run: bash install-klasiko-macos.sh
#   3. Enter your password when prompted (for symlink creation)
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Version detection - finds the latest Klasiko DMG in current directory
DMG_FILE=$(ls -t Klasiko-*-macOS.dmg 2>/dev/null | head -n 1)

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}           Klasiko PDF Converter - macOS Installer         ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check if DMG exists
if [ -z "$DMG_FILE" ]; then
    echo -e "${RED}✗ Error: Klasiko DMG not found in current directory${NC}"
    echo ""
    echo "Please download the Klasiko DMG file and this script to the same folder."
    echo ""
    echo "Download from: https://github.com/zeidalqadri/klasiko/releases"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Found: $DMG_FILE${NC}"
echo ""

# Step 2: Mount the DMG
echo -e "${YELLOW}[1/6]${NC} Mounting Klasiko DMG..."
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" | grep "/Volumes" | awk '{print $3}')

if [ -z "$MOUNT_POINT" ]; then
    echo -e "${RED}✗ Failed to mount DMG${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Mounted at: $MOUNT_POINT${NC}"
echo ""

# Step 3: Check if app exists in DMG
APP_NAME="Klasiko.app"
if [ ! -d "$MOUNT_POINT/$APP_NAME" ]; then
    echo -e "${RED}✗ Error: $APP_NAME not found in DMG${NC}"
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 1
fi

# Step 4: Copy to Applications
echo -e "${YELLOW}[2/6]${NC} Installing to /Applications..."

if [ -d "/Applications/$APP_NAME" ]; then
    echo -e "${YELLOW}⚠ Existing installation found. Removing...${NC}"
    rm -rf "/Applications/$APP_NAME"
fi

cp -R "$MOUNT_POINT/$APP_NAME" /Applications/

if [ ! -d "/Applications/$APP_NAME" ]; then
    echo -e "${RED}✗ Failed to copy app to Applications${NC}"
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 1
fi

echo -e "${GREEN}✓ Installed to /Applications/$APP_NAME${NC}"
echo ""

# Step 5: Remove quarantine attribute (THE KEY FIX)
echo -e "${YELLOW}[3/6]${NC} Removing macOS quarantine attribute..."
echo -e "      ${BLUE}(This allows the unsigned app to run)${NC}"

xattr -cr "/Applications/$APP_NAME"

echo -e "${GREEN}✓ Quarantine attribute removed${NC}"
echo ""

# Step 6: Unmount DMG
echo -e "${YELLOW}[4/6]${NC} Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -quiet
echo -e "${GREEN}✓ DMG unmounted${NC}"
echo ""

# Step 7: Create command-line symlink (optional, requires sudo)
echo -e "${YELLOW}[5/6]${NC} Creating command-line shortcut..."
echo -e "      ${BLUE}(Allows you to use 'klasiko' command in Terminal)${NC}"

SYMLINK_PATH="/usr/local/bin/klasiko"
EXECUTABLE_PATH="/Applications/$APP_NAME/Contents/MacOS/klasiko"

# Check if /usr/local/bin exists, create if not
if [ ! -d "/usr/local/bin" ]; then
    echo "Creating /usr/local/bin directory (requires password)..."
    sudo mkdir -p /usr/local/bin
fi

# Remove old symlink if it exists
if [ -L "$SYMLINK_PATH" ]; then
    echo "Removing old symlink (requires password)..."
    sudo rm "$SYMLINK_PATH"
fi

# Create new symlink
echo "Creating symlink (requires password)..."
if sudo ln -sf "$EXECUTABLE_PATH" "$SYMLINK_PATH"; then
    echo -e "${GREEN}✓ Command-line shortcut created${NC}"
    echo -e "  You can now use: ${BLUE}klasiko${NC} from any Terminal"
else
    echo -e "${YELLOW}⚠ Could not create symlink (skipping, not critical)${NC}"
fi
echo ""

# Step 8: Verify installation
echo -e "${YELLOW}[6/6]${NC} Verifying installation..."

if [ -d "/Applications/$APP_NAME" ]; then
    echo -e "${GREEN}✓ App installed successfully${NC}"
fi

# Test if executable works
if "$EXECUTABLE_PATH" --help > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Executable works${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify executable (may need full environment)${NC}"
fi

# Check if symlink works
if [ -L "$SYMLINK_PATH" ] && [ -x "$SYMLINK_PATH" ]; then
    echo -e "${GREEN}✓ Command-line access: klasiko${NC}"
fi

echo ""

# Success summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                 INSTALLATION SUCCESSFUL!                   ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Klasiko is now installed and ready to use!${NC}"
echo ""
echo "You can:"
echo -e "  ${GREEN}1.${NC} Open ${BLUE}Klasiko${NC} from the Applications folder"
echo -e "  ${GREEN}2.${NC} Use the command: ${BLUE}klasiko document.md${NC}"
echo -e "  ${GREEN}3.${NC} Launch GUI: ${BLUE}python3 klasiko-gui.py${NC} (if you have source)"
echo ""
echo "Example commands:"
echo -e "  ${BLUE}klasiko report.md --theme warm --toc${NC}"
echo -e "  ${BLUE}klasiko doc.md --logo logo.png --logo-placement \"title:large\"${NC}"
echo ""
echo "Need help?"
echo -e "  ${BLUE}klasiko --help${NC}"
echo -e "  Visit: ${BLUE}https://github.com/zeidalqadri/klasiko${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Klasiko is not signed with an Apple Developer certificate."
echo "This is normal for free, open-source software. The script removed"
echo "the quarantine attribute to allow it to run safely."
echo ""
