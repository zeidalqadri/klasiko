#!/bin/bash

# Klasiko Interactive Quick Action
# Multi-step dialog workflow for PDF conversion with logo branding
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

    # Count placements for notification
    IFS=';' read -ra LOGO_SELECTIONS <<< "$LOGO_OPTIONS"
    PLACEMENT_COUNT=${#LOGO_SELECTIONS[@]}
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
