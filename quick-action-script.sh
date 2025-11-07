#!/bin/bash

# Klasiko Quick Action - Convert Markdown to PDF with Theme Selection
# Simpler version with better error handling

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"

# Ask user to select theme using AppleScript
THEME=$(osascript <<EOF
tell application "System Events"
    activate
    set themeChoice to button returned of (display dialog "Choose PDF theme:" buttons {"Default", "Warm", "Rustic"} default button "Warm" with title "Klasiko PDF Converter")
    return themeChoice
end tell
EOF
)

# Convert theme to lowercase
THEME=$(echo "$THEME" | tr '[:upper:]' '[:lower:]')

# Check if user cancelled (empty response)
if [ -z "$THEME" ]; then
    osascript -e 'display notification "Conversion cancelled" with title "Klasiko"'
    exit 0
fi

# Process each selected file
for file in "$@"
do
    # Only process .md files
    if [[ "$file" == *.md ]]; then
        # Get output filename
        output_file="${file%.md}.pdf"
        filename=$(basename "$file")

        # Run klasiko using the global command
        klasiko "$file" -o "$output_file" --theme "$THEME" 2>&1

        # Check result
        if [ $? -eq 0 ] && [ -f "$output_file" ]; then
            osascript -e "display notification \"Converted: $filename\" with title \"Klasiko ($THEME theme)\" sound name \"Glass\""
        else
            osascript -e "display notification \"Failed: $filename\" with title \"Klasiko Error\" sound name \"Basso\""
        fi
    fi
done
