#!/bin/bash

# Klasiko Shared Dialog Library
# Reusable AppleScript dialog functions for interactive PDF conversion

# Show theme selection dialog
# Returns: "default", "warm", or "rustic" (lowercase)
# Returns empty string if cancelled
show_theme_dialog() {
    local step_text="${1:-Step 1/5}"  # Allow custom step counter

    local theme=$(osascript <<EOF
tell application "System Events"
    activate
    set themeChoice to button returned of (display dialog "Choose PDF theme:" buttons {"Default", "Warm", "Rustic"} default button "Warm" with title "Klasiko PDF Converter - $step_text")
    return themeChoice
end tell
EOF
)

    [ -z "$theme" ] && return 1
    echo "$theme" | tr '[:upper:]' '[:lower:]'
}

# Show Table of Contents dialog
# Returns: "yes" or "no"
# Returns empty string if cancelled
show_toc_dialog() {
    local step_text="${1:-Step 2/5}"  # Allow custom step counter

    local toc_choice=$(osascript <<EOF
tell application "System Events"
    activate
    set tocChoice to button returned of (display dialog "Include Table of Contents?" buttons {"No", "Yes"} default button "No" with title "Klasiko PDF Converter - $step_text")
    return tocChoice
end tell
EOF
)

    [ -z "$toc_choice" ] && return 1
    echo "$toc_choice" | tr '[:upper:]' '[:lower:]'
}

# Show logo selection dialog (Yes/No)
# Returns: "Select Logo" or "No Logo"
# Returns empty string if cancelled
show_logo_choice_dialog() {
    local step_text="${1:-Step 3/5}"  # Allow custom step counter

    local logo_choice=$(osascript <<EOF
tell application "System Events"
    activate
    set logoChoice to button returned of (display dialog "Add company logo to PDF?" buttons {"No Logo", "Select Logo"} default button "No Logo" with title "Klasiko PDF Converter - $step_text")
    return logoChoice
end tell
EOF
)

    [ -z "$logo_choice" ] && return 1
    echo "$logo_choice"
}

# Show file picker for logo selection
# Returns: POSIX path to selected logo file
# Returns empty string if cancelled
show_logo_file_picker() {
    local step_text="${1:-Step 4/5}"  # Allow custom step counter

    local logo_path=$(osascript <<EOF
tell application "System Events"
    activate
    set logoFile to choose file with prompt "Select company logo:" of type {"PNG", "public.png", "SVG", "public.svg-image", "JPEG", "public.jpeg", "JPG"} default location (path to desktop folder)
    return POSIX path of logoFile
end tell
EOF
)

    [ -z "$logo_path" ] && return 1
    echo "$logo_path"
}

# Show logo placements multi-select dialog
# Returns: semicolon-separated list like "Title Page - Large;Header - Small;Footer - Small"
# Returns empty string if cancelled
show_logo_placements_dialog() {
    local step_text="${1:-Step 5/5}"  # Allow custom step counter

    local logo_options=$(osascript <<EOF
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
        with title "Klasiko PDF Converter - $step_text"

    if selectedOptions is false then return ""

    -- Join selected options with semicolon delimiter
    set AppleScript's text item delimiters to ";"
    set optionsString to selectedOptions as string
    set AppleScript's text item delimiters to ""

    return optionsString
end tell
EOF
)

    [ -z "$logo_options" ] && return 1
    echo "$logo_options"
}

# Parse logo selections and build CLI arguments
# Input: semicolon-separated selections like "Title Page - Large;Header - Small"
# Output: CLI arguments like '--logo-placement "title:large" --logo-placement "header:small"'
parse_logo_selections() {
    local logo_options="$1"
    local logo_args=""

    # Parse multiple logo options (semicolon-separated)
    IFS=';' read -ra LOGO_SELECTIONS <<< "$logo_options"

    for selection in "${LOGO_SELECTIONS[@]}"; do
        # Parse "Position - Size" format
        local position=$(echo "$selection" | sed 's/ - .*//' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        local size=$(echo "$selection" | sed 's/.* - //' | tr '[:upper:]' '[:lower:]')

        # Handle "Watermark" which has no size suffix
        if [[ "$selection" == "Watermark" ]]; then
            position="watermark"
            size="medium"
        fi

        # Map friendly names to actual CLI values
        case "$position" in
            "title-page") position="title" ;;
            "both-header-&-footer") position="both" ;;
            "everywhere") position="all" ;;
        esac

        # Add to arguments
        logo_args="$logo_args --logo-placement \"$position:$size\""
    done

    echo "$logo_args"
}

# Show cancellation notification
show_cancel_notification() {
    osascript -e 'display notification "Conversion cancelled" with title "Klasiko"' 2>/dev/null
}

# Show error notification
show_error_notification() {
    local message="${1:-Conversion failed}"
    osascript -e "display notification \"$message\" with title \"❌ Klasiko\" sound name \"Basso\"" 2>/dev/null
}

# Show success notification
show_success_notification() {
    local message="${1:-Conversion complete}"
    osascript -e "display notification \"$message\" with title \"✅ Klasiko\" sound name \"Glass\"" 2>/dev/null
}
