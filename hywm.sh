#!/bin/bash

# --- Configuration and Colors ---
CONFIG_DIR="$HOME/.config/hypr-sm"

# ANSI Color Codes
C_BLUE='\033[1;34m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_BOLD='\033[1m'
C_NC='\033[0m' # No Color

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# --- UI Functions ---
print_header() {
echo '
██   ██ ██    ██ ██     ██ ███    ███ 
██   ██  ██  ██  ██     ██ ████  ████ 
███████   ████   ██  █  ██ ██ ████ ██ 
██   ██    ██    ██ ███ ██ ██  ██  ██ 
██   ██    ██     ███ ███  ██      ██ 
'
}

print_usage() {
    print_header
    echo -e "${C_BOLD}HyWM - Hyprland Workspace Manager${C_NC}"
    echo -e "Usage: $0 [command] [session_name]"
    echo -e ""
    echo -e "${C_YELLOW}Commands:${C_NC}"
    echo -e "  ${C_BOLD}setup  [name]${C_NC}  - Create a new or overwrite an existing session."
    echo -e "  ${C_BOLD}launch [name]${C_NC}  - Launch the apps for a specific session in parallel."
    echo -e "  ${C_BOLD}list${C_NC}           - List all available sessions."
    echo -e "  ${C_BOLD}delete [name]${C_NC}  - Delete a specific session."
}

# --- Core Logic Functions ---

# Use bash's `compgen` to get a list of all available commands.
select_app_with_fzf() {
    compgen -c | sort -u | fzf --prompt="Select an application: " --height=40% --border --layout=reverse
}

list_sessions() {
    print_header
    echo -e "${C_YELLOW}Available sessions:${C_NC}"
    find "$CONFIG_DIR" -maxdepth 1 -name "*.conf" -printf "%f\n" | sed 's/\.conf$//' | sed 's/^/  - /'
}

run_setup() {
    print_header
    local session_name="$1"
    if [[ -z "$session_name" ]]; then
        echo -e -n "${C_YELLOW}Enter a name for this new session (e.g., 'work', 'gaming'): ${C_NC}"
        read session_name
        if [[ -z "$session_name" ]]; then echo -e "${C_RED}Error: Session name cannot be empty.${C_NC}"; exit 1; fi
    fi

    local config_file="$CONFIG_DIR/$session_name.conf"
    if [ -f "$config_file" ]; then
        echo -e -n "${C_YELLOW}Session '${C_BOLD}$session_name${C_NC}${C_YELLOW}' already exists. Overwrite? [y/N]: ${C_NC}"
        read confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then echo "Setup cancelled."; exit 0; fi
    fi

    echo -e "${C_BLUE}Starting setup for session: '${C_BOLD}$session_name${C_NC}${C_BLUE}'...${C_NC}"
    > "$config_file"

    while true; do
        echo -e ""
        echo -e -n "${C_YELLOW}Enter app command (or '?' to search, Enter to finish): ${C_NC}"
        read app_command
        if [[ -z "$app_command" ]]; then break; fi
        
        if [[ "$app_command" == "?" ]]; then
            app_command=$(select_app_with_fzf)
            if [[ -z "$app_command" ]]; then
                echo -e "${C_RED}No application selected.${C_NC}"
                continue
            fi
            echo -e "${C_GREEN}Selected: ${C_BOLD}$app_command${C_NC}"
        fi

        echo -e -n "${C_YELLOW}Enter workspace number for '${C_BOLD}$app_command${C_NC}${C_YELLOW}': ${C_NC}"
        read workspace
        if ! [[ "$workspace" =~ ^[1-9][0-9]*$ ]]; then echo -e "${C_RED}Invalid input. Skipping.${C_NC}"; continue; fi

        echo "$workspace:$app_command" >> "$config_file"
        echo -e "${C_GREEN}Added to '${C_BOLD}$session_name${C_NC}${C_GREEN}': '$app_command' -> Workspace $workspace${C_NC}"
    done
    echo -e "\n${C_GREEN}Setup for session '${C_BOLD}$session_name${C_NC}${C_GREEN}' complete.${C_NC}"
}

launch_session() {
    local session_name="$1"
    if [[ -z "$session_name" ]]; then echo -e "${C_RED}Error: Please specify which session to launch.${C_NC}\n"; list_sessions; exit 1; fi

    local config_file="$CONFIG_DIR/$session_name.conf"
    if [[ ! -f "$config_file" ]]; then echo -e "${C_RED}Error: Session '${C_BOLD}$session_name${C_NC}${C_RED}' not found!${C_NC}"; exit 1; fi

    # This function takes a single line (e.g., "1:kitty") and executes the launch command.
    launch_line_job() {
        local line="$1"
        local workspace="${line%%:*}"
        local app_command="${line#*:}"
        
        C_BOLD='\033[1m'
        C_NC='\033[0m'

        echo -e "  -> Dispatching ${C_BOLD}$app_command${C_NC} to workspace ${C_BOLD}$workspace${C_NC}..."
        hyprctl dispatch workspace "$workspace"
        sleep 1
        bash -c "$app_command &"
    }
    export -f launch_line_job

    print_header
    echo -e "${C_BLUE}Launching session '${C_BOLD}$session_name${C_NC}${C_BLUE}' in parallel...${C_NC}"

    <"$config_file" sed '/^$/d' | parallel --no-notice -j 0 launch_line_job {}

    echo -e "\n${C_GREEN}All launch commands for session '${C_BOLD}$session_name${C_NC}${C_GREEN}' have been dispatched.${C_NC}"
}

delete_session() {
    print_header
    local session_name="$1"
    if [[ -z "$session_name" ]]; then echo -e "${C_RED}Error: Please specify which session to delete.${C_NC}\n"; list_sessions; exit 1; fi

    local config_file="$CONFIG_DIR/$session_name.conf"
    if [[ ! -f "$config_file" ]]; then echo -e "${C_RED}Error: Session '${C_BOLD}$session_name${C_NC}${C_RED}' not found!${C_NC}"; exit 1; fi

    echo -e -n "${C_YELLOW}Are you sure you want to delete session '${C_BOLD}$session_name${C_NC}${C_YELLOW}'? [y/N]: ${C_NC}"
    read confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm "$config_file"
        echo -e "${C_GREEN}Session '${C_BOLD}$session_name${C_NC}${C_GREEN}' deleted.${C_NC}"
    else
        echo "Deletion cancelled."
    fi
}

# --- Main script logic ---
COMMAND="$1"
SESSION_NAME="$2"

case "$COMMAND" in
    setup)         run_setup "$SESSION_NAME" ;; 
    launch)        launch_session "$SESSION_NAME" ;; 
    list)          list_sessions ;; 
    delete)        delete_session "$SESSION_NAME" ;; 
    *)             print_usage; exit 1 ;; 
esac
