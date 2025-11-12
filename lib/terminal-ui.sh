#!/bin/bash

# Klasiko Terminal UI Library
# Pure terminal-based interactive prompts (no GUI dialogs)

# ANSI Color Codes (using $'...' for proper escape sequence interpretation)
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
RED=$'\033[0;31m'
GRAY=$'\033[0;90m'
MAGENTA=$'\033[0;35m'

# Unicode Symbols
CHECK='✓'
CROSS='✗'
ARROW='→'
BULLET='•'

# Print banner
print_banner() {
    echo "" >&2
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}" >&2
    echo -e "${BOLD}${BLUE}║${RESET}                  ${BOLD}KLASIKO PDF CONVERTER${RESET}                   ${BOLD}${BLUE}║${RESET}" >&2
    echo -e "${BOLD}${BLUE}║${RESET}                 ${DIM}Terminal Interactive Mode${RESET}                ${BOLD}${BLUE}║${RESET}" >&2
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}" >&2
    echo "" >&2
}

# Show theme selection menu
# Returns: "default", "warm", or "rustic" (lowercase)
show_theme_selection() {
    local result=""

    # All display output goes to stderr
    {
        echo -e "${BOLD}${CYAN}Step 1/5: Choose PDF Theme${RESET}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""

        # Use bash select for simple, bulletproof menu
        PS3=$'\n'"${CYAN}Select theme (1-3):${RESET} "

        local options=("Default - Clean white paper" "Warm - Neutral tones (recommended)" "Rustic - Aged paper")
        select opt in "${options[@]}"; do
            case $REPLY in
                1) echo -e "${GREEN}${CHECK}${RESET} Selected: ${BOLD}Default${RESET}\n"; result="default"; break ;;
                2) echo -e "${GREEN}${CHECK}${RESET} Selected: ${BOLD}Warm${RESET}\n"; result="warm"; break ;;
                3) echo -e "${GREEN}${CHECK}${RESET} Selected: ${BOLD}Rustic${RESET}\n"; result="rustic"; break ;;
                *) echo -e "${YELLOW}Please select 1, 2, or 3${RESET}" ;;
            esac
        done
    } >&2

    # Return the result to stdout
    echo "$result"
}

# Show yes/no prompt
# Args: $1 = prompt text, $2 = default (y or n)
# Returns: "yes" or "no"
show_yes_no_prompt() {
    local prompt="$1"
    local default="${2:-n}"

    local yn_display
    if [[ "$default" == "y" ]]; then
        yn_display="${BOLD}Y${RESET}/${DIM}n${RESET}"
    else
        yn_display="${DIM}y${RESET}/${BOLD}N${RESET}"
    fi

    while true; do
        echo -en "${CYAN}${prompt}${RESET} [${yn_display}]: " >&2
        read -r response

        # Use default if empty
        response="${response:-$default}"

        # Bash 3.2 compatible lowercase conversion
        response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')

        case "$response_lower" in
            y|yes) echo "yes"; return 0 ;;
            n|no) echo "no"; return 0 ;;
            *) echo -e "${YELLOW}Please answer yes or no${RESET}" >&2 ;;
        esac
    done
}

# Show file path input with validation
# Args: $1 = prompt text, $2 = file types regex (e.g., "png|svg|jpg|jpeg")
# Returns: validated file path
show_file_input() {
    local prompt="$1"
    local file_types="$2"

    echo "" >&2
    echo -e "${BOLD}${CYAN}${prompt}${RESET}" >&2
    echo -e "${GRAY}(Use tab completion, ~ for home directory)${RESET}" >&2

    while true; do
        echo -en "${BLUE}${ARROW}${RESET} " >&2

        # Enable readline for tab completion
        read -e -r filepath

        # Handle empty input
        if [[ -z "$filepath" ]]; then
            echo -e "${RED}${CROSS} Path required${RESET}" >&2
            continue
        fi

        # Expand ~ to home directory
        filepath="${filepath/#\~/$HOME}"

        # Check if file exists
        if [[ ! -f "$filepath" ]]; then
            echo -e "${RED}${CROSS} File not found: $filepath${RESET}" >&2
            continue
        fi

        # Validate file extension (case insensitive)
        local ext="${filepath##*.}"
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        if [[ ! "$ext_lower" =~ ^($file_types)$ ]]; then
            echo -e "${RED}${CROSS} Invalid file type. Supported: ${file_types}${RESET}" >&2
            continue
        fi

        echo -e "${GREEN}${CHECK}${RESET} Valid logo: ${BOLD}$(basename "$filepath")${RESET}" >&2
        echo "" >&2
        echo "$filepath"
        return 0
    done
}

# Show multi-select menu with checkboxes
# Args: $1 = prompt text, $@ = options array
# Returns: semicolon-separated selected options
show_multi_select() {
    local prompt="$1"
    shift
    local -a options=("$@")

    # If only one option, just show simple numbered list
    if [[ ${#options[@]} -le 5 ]]; then
        show_simple_multi_select "$prompt" "${options[@]}"
        return $?
    fi

    # For many options, use simpler numbered selection
    show_simple_multi_select "$prompt" "${options[@]}"
}

# Simpler multi-select using numbers (more reliable than arrow keys)
show_simple_multi_select() {
    local prompt="$1"
    shift
    local -a options=("$@")
    local -a selected=()

    echo "" >&2
    echo -e "${BOLD}${CYAN}${prompt}${RESET}" >&2
    echo -e "${GRAY}Enter numbers separated by spaces (e.g., 1 3 5), or 'all', or press Enter when done${RESET}" >&2
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    echo "" >&2

    # Display options
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        echo -e "  ${DIM}$num)${RESET} ${options[$i]}" >&2
    done

    echo "" >&2

    while true; do
        echo -en "${CYAN}Select placements:${RESET} " >&2
        read -r selection

        # Handle empty (finish)
        if [[ -z "$selection" ]]; then
            if [[ ${#selected[@]} -eq 0 ]]; then
                echo -e "${YELLOW}Please select at least one option${RESET}" >&2
                continue
            else
                break
            fi
        fi

        # Handle 'all' (bash 3.2 compatible)
        selection_lower=$(echo "$selection" | tr '[:upper:]' '[:lower:]')
        if [[ "$selection_lower" == "all" ]]; then
            for opt in "${options[@]}"; do
                selected+=("$opt")
            done
            echo -e "${GREEN}${CHECK} Selected all placements${RESET}" >&2
            break
        fi

        # Parse numbers
        local -a indices=($selection)
        local valid=true
        local -a temp_selected=()

        for idx in "${indices[@]}"; do
            # Validate it's a number
            if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
                echo -e "${YELLOW}Invalid input: '$idx' is not a number${RESET}" >&2
                valid=false
                break
            fi

            # Convert to 0-based index
            local array_idx=$((idx - 1))

            # Validate range
            if [[ $array_idx -lt 0 ]] || [[ $array_idx -ge ${#options[@]} ]]; then
                echo -e "${YELLOW}Invalid option: $idx (must be 1-${#options[@]})${RESET}" >&2
                valid=false
                break
            fi

            temp_selected+=("${options[$array_idx]}")
        done

        if [[ "$valid" == true ]]; then
            selected=("${temp_selected[@]}")

            # Show what was selected
            echo -e "${GREEN}${CHECK} Selected: ${BOLD}${#selected[@]} placement(s)${RESET}" >&2
            for item in "${selected[@]}"; do
                echo -e "    ${BULLET} $item" >&2
            done
            echo "" >&2

            # Ask if done or want to add more
            echo -en "${CYAN}Add more? (y/N):${RESET} " >&2
            read -r add_more

            # Bash 3.2 compatible lowercase conversion
            add_more_lower=$(echo "$add_more" | tr '[:upper:]' '[:lower:]')
            if [[ ! "$add_more_lower" =~ ^y ]]; then
                break
            fi
        fi
    done

    # Return selected options as semicolon-separated string
    local result=""
    for item in "${selected[@]}"; do
        result+="${item};"
    done

    echo "${result%;}"  # Remove trailing semicolon
}

# Parse logo selections and build CLI arguments
# Same function from dialogs.sh for compatibility
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

# Show files to be converted
show_files_list() {
    local -a files=("$@")

    echo -e "${BOLD}Files to convert:${RESET}" >&2
    for file in "${files[@]}"; do
        local filename=$(basename "$file")
        echo -e "  ${BLUE}${ARROW}${RESET} ${filename}" >&2
    done
    echo "" >&2
}
