# Klasiko Interactive Quick Action Setup

## Overview

Create a right-click menu option that guides you through:
1. **Theme selection** (Default / Warm / Rustic)
2. **Logo branding** (optional - select logo file and placement)
3. **Automatic conversion** with your choices

## Quick Setup (5 minutes)

### Step 1: Open Automator
1. Press **⌘+Space**, type "Automator", press Enter
2. Click **"New Document"**
3. Choose **"Quick Action"**
4. Click **"Choose"**

### Step 2: Configure Workflow
In the top panel:
1. Set **"Workflow receives current"** to: **"files or folders"**
2. Set **"in"** to: **"Finder"**

### Step 3: Add Shell Script
1. Search for **"Run Shell Script"** in left sidebar
2. Drag it to the workflow area
3. Set **Shell** to: **/bin/bash**
4. Set **"Pass input"** to: **"as arguments"**

### Step 4: Paste the Script
Copy and paste the entire script from `/Users/zeidalqadri/Desktop/klasiko/quick-action-interactive.sh` into the script box.

Or copy this script:

```bash
#!/bin/bash

# Klasiko Interactive Quick Action
SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"

# Step 1: Theme Selection
THEME=$(osascript <<EOF
tell application "System Events"
    activate
    set themeChoice to button returned of (display dialog "Choose PDF theme:" buttons {"Default", "Warm", "Rustic"} default button "Warm" with title "Klasiko - Step 1/4")
    return themeChoice
end tell
EOF
)

[ -z "$THEME" ] && osascript -e 'display notification "Cancelled" with title "Klasiko"' && exit 0
THEME=$(echo "$THEME" | tr '[:upper:]' '[:lower:]')

# Step 2: Logo Question
LOGO_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set logoChoice to button returned of (display dialog "Add company logo?" buttons {"No Logo", "Select Logo"} default button "No Logo" with title "Klasiko - Step 2/4")
    return logoChoice
end tell
EOF
)

[ -z "$LOGO_CHOICE" ] && osascript -e 'display notification "Cancelled" with title "Klasiko"' && exit 0

LOGO_PATH=""; LOGO_POSITION=""; LOGO_SIZE=""

# Step 3: File Picker (if logo selected)
if [ "$LOGO_CHOICE" = "Select Logo" ]; then
    LOGO_PATH=$(osascript <<EOF
tell application "System Events"
    activate
    set logoFile to choose file with prompt "Select logo:" of type {"PNG", "public.png", "SVG", "public.svg-image", "JPEG", "public.jpeg"} default location (path to desktop folder)
    return POSIX path of logoFile
end tell
EOF
)

    [ -z "$LOGO_PATH" ] && osascript -e 'display notification "No logo selected" with title "Klasiko"' && exit 0

    # Step 4: Logo Options
    LOGO_OPTIONS=$(osascript <<EOF
tell application "System Events"
    activate
    set pos to button returned of (display dialog "Logo placement:" buttons {"Header", "Footer", "Both", "Title Page", "Watermark", "Everywhere"} default button "Header" with title "Klasiko - Step 3/4")
    set sz to button returned of (display dialog "Logo size:" buttons {"Small", "Medium", "Large"} default button "Medium" with title "Klasiko - Step 4/4")
    return pos & "|" & sz
end tell
EOF
)

    [ -z "$LOGO_OPTIONS" ] && osascript -e 'display notification "Cancelled" with title "Klasiko"' && exit 0

    LOGO_POSITION=$(echo "$LOGO_OPTIONS" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    LOGO_SIZE=$(echo "$LOGO_OPTIONS" | cut -d'|' -f2 | tr '[:upper:]' '[:lower:]')

    case "$LOGO_POSITION" in
        "title-page") LOGO_POSITION="title" ;;
        "everywhere") LOGO_POSITION="all" ;;
    esac
fi

# Convert files
for file in "$@"; do
    [[ "$file" != *.md ]] && continue

    output_file="${file%.md}.pdf"
    filename=$(basename "$file")

    CMD="klasiko \"$file\" -o \"$output_file\" --theme \"$THEME\""
    [ -n "$LOGO_PATH" ] && CMD="$CMD --logo \"$LOGO_PATH\" --logo-position \"$LOGO_POSITION\" --logo-size \"$LOGO_SIZE\""

    eval $CMD 2>&1

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        MSG="Converted with $THEME theme"
        [ -n "$LOGO_PATH" ] && MSG="$MSG + logo"
        osascript -e "display notification \"$MSG\" with title \"✓ $filename\" sound name \"Glass\""
    else
        osascript -e "display notification \"Conversion failed\" with title \"✗ $filename\" sound name \"Basso\""
    fi
done
```

### Step 5: Save
1. Press **⌘S** or **File → Save**
2. Name it: **"Convert to PDF with Klasiko"**
3. Location: Automatically saves to `~/Library/Services/`

### Step 6: Enable (if needed)
- **System Settings** → **Extensions** → **Finder**
- Ensure **"Convert to PDF with Klasiko"** is checked

## How to Use

### Basic Workflow:
1. **Right-click** any `.md` file in Finder
2. **Quick Actions** → **"Convert to PDF with Klasiko"**
3. **Dialog 1**: Choose theme (Default/Warm/Rustic)
4. **Dialog 2**: Add logo? (No Logo / Select Logo)
5. **Dialog 3** (if logo): Browse and select logo file
6. **Dialog 4** (if logo): **⌘-Click multiple positions** from list (e.g., "Title Page - Large", "Header - Small")
7. **Done!** Notification appears when PDF is ready

### Examples:
- **Quick conversion**: Just pick theme → No Logo → Done
- **Single position**: Pick theme → Select Logo → Choose "Header - Medium"
- **Multi-position branding** **[NEW v2.1]**: Pick theme → Select Logo → ⌘-Click "Title Page - Large" + "Header - Small" + "Footer - Small"
- **Full branding**: Pick Rustic → Logo → ⌘-Click "Title Page - Large" + "Both - Small" + "Watermark"

## Features

✅ **Multi-step wizard** - Clear, guided workflow
✅ **Theme selection** - 3 visual styles
✅ **Optional logo** - Skip if not needed
✅ **File picker** - Browse for logo visually
✅ **Multi-position placement** **[NEW v2.1]** - ⌘-Click to select multiple positions (e.g., title + header + footer)
✅ **Individual sizes per position** **[NEW v2.1]** - Different sizes for each position (e.g., large on title, small in header)
✅ **Single-select list** - All position+size combinations in one dialog
✅ **3 sizes per position** - Small, medium, large for each placement
✅ **Multiple files** - Select and convert batch
✅ **Smart notifications** - Success/error feedback

## Troubleshooting

### Quick Action doesn't appear
- Restart Finder: **Option + Right-click Finder icon** → **Relaunch**
- Check **System Settings** → **Extensions** → **Finder**

### Script error
- Open **Console.app**, search "Automator" for errors
- Verify `/Users/zeidalqadri/Desktop/klasiko/` path is correct
- Test manually: `klasiko --help`

### Logo not appearing
- Supported formats: PNG, SVG, JPG/JPEG only
- Check logo file isn't corrupted: Open in Preview
- Try smaller logo file (< 500KB recommended)

## Command-Line Alternative

If you prefer command-line, use these examples:

```bash
# No logo
klasiko document.md --theme warm

# Single position (old format - still works)
klasiko document.md --logo company-logo.png --logo-position header --logo-size medium

# Multi-position branding [NEW v2.1]
klasiko document.md --logo brand.svg \
  --logo-placement "title:large" \
  --logo-placement "header:small" \
  --logo-placement "footer:small"

# Professional report
klasiko document.md --logo logo.png \
  --logo-placement "title:large" \
  --logo-placement "header:small" \
  --theme warm

# Maximum branding
klasiko document.md --logo company.svg \
  --logo-placement "title:medium" \
  --logo-placement "both:small" \
  --logo-placement "watermark:medium"
```

## Notes

- **No TOC by default** - Faster conversions (add `--toc` flag if needed)
- **Works with global command** - Uses `klasiko` command installed in PATH
- **Supports SVG** - Vector logos scale perfectly
- **Cancel anytime** - Click Cancel in any dialog to stop
- **Multiple files** - Select multiple `.md` files, converts all

---

**Created**: 2025-11-06
**Version**: 2.0 with Logo Branding
