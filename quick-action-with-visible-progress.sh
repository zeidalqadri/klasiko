#!/bin/bash

# Klasiko Interactive Quick Action - With Visible Progress
# Shows progress in a Terminal window so you can see what's happening

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"

# Step 1: Choose theme
THEME=$(osascript <<EOF
tell application "System Events"
    activate
    set themeChoice to button returned of (display dialog "Choose PDF theme:" buttons {"Default", "Warm", "Rustic"} default button "Warm" with title "Klasiko PDF Converter - Step 1/4")
    return themeChoice
end tell
EOF
)

[ -z "$THEME" ] && exit 0
THEME=$(echo "$THEME" | tr '[:upper:]' '[:lower:]')

# Step 2: Ask about logo
LOGO_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set logoChoice to button returned of (display dialog "Add company logo to PDF?" buttons {"No Logo", "Select Logo"} default button "No Logo" with title "Klasiko PDF Converter - Step 2/4")
    return logoChoice
end tell
EOF
)

[ -z "$LOGO_CHOICE" ] && exit 0

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

    [ -z "$LOGO_PATH" ] && exit 0

    # Step 4: Logo Placements (multi-select with position + size)
    LOGO_OPTIONS=$(osascript <<EOF
tell application "System Events"
    activate

    -- Combined position + size options
    set logoOptionsList to {"Title Page - Small", "Title Page - Medium", "Title Page - Large", ¬
                            "Header - Small", "Header - Medium", "Header - Large", ¬
                            "Footer - Small", "Footer - Medium", "Footer - Large", ¬
                            "Both Header & Footer - Small", "Both Header & Footer - Medium", "Both Header & Footer - Large", ¬
                            "Watermark", ¬
                            "Everywhere - Small", "Everywhere - Medium", "Everywhere - Large"}

    set selectedOptions to choose from list logoOptionsList ¬
        with prompt "Select logo placements (⌘-Click for multiple):" ¬
        with multiple selections allowed ¬
        default items {"Header - Medium"} ¬
        with title "Klasiko PDF Converter - Step 3/4"

    if selectedOptions is false then return ""

    -- Join selected options with semicolon delimiter
    set AppleScript's text item delimiters to ";"
    set optionsString to selectedOptions as string
    set AppleScript's text item delimiters to ""

    return optionsString
end tell
EOF
)

    [ -z "$LOGO_OPTIONS" ] && exit 0

    # Parse multiple logo options (semicolon-separated)
    # Format: "Title Page - Large;Header - Small;Footer - Small"
    IFS=';' read -ra LOGO_SELECTIONS <<< "$LOGO_OPTIONS"

    # Build logo placement arguments
    LOGO_ARGS=""
    for selection in "${LOGO_SELECTIONS[@]}"; do
        # Parse "Position - Size" format
        POSITION=$(echo "$selection" | sed 's/ - .*//' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        SIZE=$(echo "$selection" | sed 's/.* - //' | tr '[:upper:]' '[:lower:]')

        # Handle "Watermark" which has no size suffix
        if [[ "$selection" == "Watermark" ]]; then
            POSITION="watermark"
            SIZE="medium"
        fi

        # Map friendly names to actual values
        case "$POSITION" in
            "title-page") POSITION="title" ;;
            "both-header-&-footer") POSITION="both" ;;
            "everywhere") POSITION="all" ;;
        esac

        # Add to arguments
        LOGO_ARGS="$LOGO_ARGS --logo-placement \"$POSITION:$SIZE\""
    done
fi

# Write selected files to a temporary file for Terminal to read
FILES_LIST="/tmp/klasiko-files-$$.txt"
printf '%s\n' "$@" > "$FILES_LIST"

# Write configuration to a separate file (to avoid quote escaping issues in AppleScript)
CONFIG_FILE="/tmp/klasiko-config-$$.txt"
LOGO_ARG="NONE"
[ -n "$LOGO_PATH" ] && LOGO_ARG="$LOGO_PATH"

cat > "$CONFIG_FILE" << CONFIG_EOF
THEME="$THEME"
LOGO_PATH="$LOGO_ARG"
LOGO_ARGS="$LOGO_ARGS"
FILES_LIST="$FILES_LIST"
CONFIG_EOF

# Create a temporary script to run in Terminal
TEMP_SCRIPT="/tmp/klasiko-conversion-$$.sh"
cat > "$TEMP_SCRIPT" << 'SCRIPT_END'
#!/bin/bash

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          KLASIKO PDF CONVERSION - PROGRESS WINDOW          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Read configuration from config file
CONFIG_FILE="$1"
source "$CONFIG_FILE"

# Read files from the temporary file list
while IFS= read -r file; do
    if [[ "$file" == *.md ]]; then
        filename=$(basename "$file")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📄 Converting: $filename"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        output_file="${file%.md}.pdf"

        CMD="klasiko \"$file\" -o \"$output_file\" --theme \"$THEME\""

        if [ -n "$LOGO_PATH" ] && [ "$LOGO_PATH" != "NONE" ]; then
            CMD="$CMD --logo \"$LOGO_PATH\" $LOGO_ARGS"
        fi

        eval "$CMD"

        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ PDF created successfully!"
        else
            echo ""
            echo "❌ Conversion failed!"
        fi
        echo ""
    fi
done < "$FILES_LIST"

# Clean up temporary files
rm -f "$FILES_LIST" "$CONFIG_FILE"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    ALL CONVERSIONS COMPLETE                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Press any key to close this window..."
read -n 1 -s

SCRIPT_END

chmod +x "$TEMP_SCRIPT"

# Open Terminal and run the script (pass only the config file path - no quote escaping issues!)
osascript <<EOF
tell application "Terminal"
    activate
    set newTab to do script "$TEMP_SCRIPT \"$CONFIG_FILE\""
end tell
EOF

# Clean up temp files after a delay (files list and config are cleaned by the script itself)
(sleep 60; rm -f "$TEMP_SCRIPT") &
