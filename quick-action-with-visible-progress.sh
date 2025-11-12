#!/bin/bash

# Klasiko Interactive Quick Action - With Visible Progress
# Shows progress in a Terminal window so you can see what's happening
# Uses shared dialog library for consistency

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"
DIALOGS_LIB="$SCRIPT_DIR/lib/dialogs.sh"

# Load shared dialog functions
source "$DIALOGS_LIB"

# Step 1: Choose theme
THEME=$(show_theme_dialog "Step 1/4")
if [ $? -ne 0 ] || [ -z "$THEME" ]; then
    show_cancel_notification
    exit 0
fi

# Step 2: Ask about logo
LOGO_CHOICE=$(show_logo_choice_dialog "Step 2/4")
if [ $? -ne 0 ] || [ -z "$LOGO_CHOICE" ]; then
    show_cancel_notification
    exit 0
fi

LOGO_PATH=""
LOGO_ARGS=""

# Steps 3-4: Logo file and placements (if logo selected)
if [ "$LOGO_CHOICE" = "Select Logo" ]; then
    # Step 3: File picker
    LOGO_PATH=$(show_logo_file_picker "Step 3/4")
    if [ $? -ne 0 ] || [ -z "$LOGO_PATH" ]; then
        show_cancel_notification
        exit 0
    fi

    # Step 4: Logo placements
    LOGO_OPTIONS=$(show_logo_placements_dialog "Step 4/4")
    if [ $? -ne 0 ] || [ -z "$LOGO_OPTIONS" ]; then
        show_cancel_notification
        exit 0
    fi

    # Parse selections into CLI arguments
    LOGO_ARGS=$(parse_logo_selections "$LOGO_OPTIONS")
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
