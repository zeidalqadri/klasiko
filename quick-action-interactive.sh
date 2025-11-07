#!/bin/bash

# Klasiko Interactive Quick Action
# Multi-step dialog workflow for PDF conversion with logo branding

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

# Check if user cancelled
if [ -z "$THEME" ]; then
    osascript -e 'display notification "Conversion cancelled" with title "Klasiko"'
    exit 0
fi

# Convert theme to lowercase
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

# Check if user cancelled
if [ -z "$LOGO_CHOICE" ]; then
    osascript -e 'display notification "Conversion cancelled" with title "Klasiko"'
    exit 0
fi

# Initialize logo variables
LOGO_PATH=""
LOGO_POSITION=""
LOGO_SIZE=""

# Step 3: If user wants logo, show file picker
if [ "$LOGO_CHOICE" = "Select Logo" ]; then
    LOGO_PATH=$(osascript <<EOF
tell application "System Events"
    activate
    set logoFile to choose file with prompt "Select company logo:" of type {"PNG", "public.png", "SVG", "public.svg-image", "JPEG", "public.jpeg", "JPG"} default location (path to desktop folder)
    return POSIX path of logoFile
end tell
EOF
)

    # Check if user cancelled file picker
    if [ -z "$LOGO_PATH" ]; then
        osascript -e 'display notification "Conversion cancelled - no logo selected" with title "Klasiko"'
        exit 0
    fi

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

    # Check if user cancelled
    if [ -z "$LOGO_OPTIONS" ]; then
        osascript -e 'display notification "Conversion cancelled" with title "Klasiko"'
        exit 0
    fi

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

# Process each selected file
for file in "$@"
do
    # Only process .md files
    if [[ "$file" == *.md ]]; then
        output_file="${file%.md}.pdf"
        filename=$(basename "$file")

        # Show starting notification
        osascript -e "display notification \"Starting conversion...\" with title \"⏳ $filename\""

        # Build klasiko command
        CMD="klasiko \"$file\" -o \"$output_file\" --theme \"$THEME\""

        # Add logo arguments if logo was selected
        if [ -n "$LOGO_PATH" ]; then
            CMD="$CMD --logo \"$LOGO_PATH\" $LOGO_ARGS"
        fi

        # Run conversion
        eval $CMD 2>&1

        # Check result
        if [ $? -eq 0 ] && [ -f "$output_file" ]; then
            # Success notification with details
            if [ -n "$LOGO_PATH" ]; then
                # Count placements
                PLACEMENT_COUNT=$(echo "$LOGO_SELECTIONS" | wc -w | tr -d ' ')
                if [ "$PLACEMENT_COUNT" -gt 1 ]; then
                    osascript -e "display notification \"Theme: $THEME + logo ($PLACEMENT_COUNT positions)\" with title \"✅ $filename\" sound name \"Glass\""
                else
                    osascript -e "display notification \"Theme: $THEME + logo\" with title \"✅ $filename\" sound name \"Glass\""
                fi
            else
                osascript -e "display notification \"Theme: $THEME\" with title \"✅ $filename\" sound name \"Glass\""
            fi

            # Open Finder to show the created PDF
            open -R "$output_file"
        else
            osascript -e "display notification \"Conversion failed - check Console.app\" with title \"❌ $filename\" sound name \"Basso\""
        fi
    else
        osascript -e "display notification \"Not a Markdown file\" with title \"⚠️ $(basename \"$file\")\" sound name \"Basso\""
    fi
done
