#!/bin/bash

# Klasiko Wrapper Script
# Provides both interactive terminal mode and CLI mode
# - Interactive mode: klasiko file.md (shows terminal prompts)
# - CLI mode: klasiko file.md --theme warm --toc (direct arguments)

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"
VENV_PATH="$SCRIPT_DIR/venv"
PYTHON_SCRIPT="$SCRIPT_DIR/klasiko.py"
TERMINAL_UI_LIB="$SCRIPT_DIR/lib/terminal-ui.sh"

# Detect interactive mode
# Interactive if: only .md files provided, no CLI flags
INTERACTIVE_MODE=false
HAS_FLAGS=false
MD_FILES=()

for arg in "$@"; do
    if [[ "$arg" == --* ]] || [[ "$arg" == -* ]]; then
        HAS_FLAGS=true
        break
    elif [[ "$arg" == *.md ]]; then
        MD_FILES+=("$arg")
    fi
done

# Enter interactive mode if we have .md files and no flags
if [ ${#MD_FILES[@]} -gt 0 ] && [ "$HAS_FLAGS" = false ]; then
    INTERACTIVE_MODE=true
fi

# ============================================================================
# INTERACTIVE MODE - Terminal-based prompts
# ============================================================================
if [ "$INTERACTIVE_MODE" = true ]; then
    # Load terminal UI functions
    source "$TERMINAL_UI_LIB"

    # Print banner
    print_banner

    # Show files that will be converted
    show_files_list "${MD_FILES[@]}"

    # Step 1: Theme selection
    THEME=$(show_theme_selection)
    if [ $? -ne 0 ] || [ -z "$THEME" ]; then
        echo -e "${YELLOW}Cancelled${RESET}"
        exit 0
    fi

    # Step 2: Table of Contents
    echo -e "${BOLD}${CYAN}Step 2/5: Options${RESET}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    TOC=$(show_yes_no_prompt "Include Table of Contents?" "n")
    echo ""

    # Step 3: Logo choice
    echo -e "${BOLD}${CYAN}Step 3/5: Logo Branding${RESET}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    LOGO_CHOICE=$(show_yes_no_prompt "Add company logo to PDF?" "n")
    echo ""

    LOGO_PATH=""
    LOGO_ARGS=""

    # Steps 4-5: Logo file and placements (if logo selected)
    if [ "$LOGO_CHOICE" = "yes" ]; then
        # Step 4: Logo file path
        echo -e "${BOLD}${CYAN}Step 4/5: Select Logo File${RESET}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        LOGO_PATH=$(show_file_input "Enter path to logo file (PNG, SVG, JPG, JPEG):" "png|svg|jpg|jpeg")
        if [ $? -ne 0 ] || [ -z "$LOGO_PATH" ]; then
            echo -e "${YELLOW}Cancelled${RESET}"
            exit 0
        fi

        # Step 5: Logo placements
        echo -e "${BOLD}${CYAN}Step 5/5: Logo Placement${RESET}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

        placement_options=(
            "Title Page - Large"
            "Title Page - Medium"
            "Title Page - Small"
            "Header - Small"
            "Header - Medium"
            "Header - Large"
            "Footer - Small"
            "Footer - Medium"
            "Footer - Large"
            "Both Header & Footer - Small"
            "Both Header & Footer - Medium"
            "Both Header & Footer - Large"
            "Watermark"
            "Everywhere - Small"
            "Everywhere - Medium"
            "Everywhere - Large"
        )

        LOGO_OPTIONS=$(show_multi_select "Select logo placements:" "${placement_options[@]}")
        if [ -z "$LOGO_OPTIONS" ]; then
            echo -e "${YELLOW}No placements selected, skipping logo${RESET}"
            LOGO_PATH=""
        else
            # Parse selections into CLI arguments
            LOGO_ARGS=$(parse_logo_selections "$LOGO_OPTIONS")
        fi
    fi

    # Build and execute command in same terminal
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                    ${BOLD}STARTING CONVERSION${RESET}                    ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Activate virtual environment
    source "$VENV_PATH/bin/activate"

    # Process each file
    for file in "${MD_FILES[@]}"; do
        CMD="python \"$PYTHON_SCRIPT\" \"$file\" --theme \"$THEME\""

        # Add TOC if selected
        [ "$TOC" = "yes" ] && CMD="$CMD --toc"

        # Add logo if selected
        if [ -n "$LOGO_PATH" ]; then
            CMD="$CMD --logo \"$LOGO_PATH\" $LOGO_ARGS"
        fi

        # Execute conversion
        eval $CMD

        echo ""
    done

    # Deactivate virtual environment
    deactivate

    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}                  ${BOLD}ALL CONVERSIONS COMPLETE${RESET}                ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    exit 0
fi

# ============================================================================
# CLI MODE - Pass through directly to klasiko.py
# ============================================================================

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Run klasiko.py with all arguments passed to this script
python "$PYTHON_SCRIPT" "$@"

# Capture exit code
exit_code=$?

# Deactivate virtual environment
deactivate

# Exit with same code as Python script
exit $exit_code
