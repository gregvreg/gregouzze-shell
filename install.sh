#!/usr/bin/env bash
# ==============================================================================
# install.sh - Installer, Manager & Updater for gregouzze-shell
# Modular Arch Linux / Hyprland Rice inspired by Caelestia Shell
# ==============================================================================

set -euo pipefail

# ANSI color codes
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_MAGENTA="\033[1;35m"
C_CYAN="\033[1;36m"

# Project paths
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_SRC="$SHELL_DIR/hypr"
QUICKSHELL_SRC="$SHELL_DIR/quickshell"
KITTY_SRC="$SHELL_DIR/kitty"
MATUGEN_SRC="$SHELL_DIR/matugen"
SCRIPTS_SRC="$SHELL_DIR/scripts"

TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_TARGET="$TARGET_CONFIG_DIR/hypr"
QUICKSHELL_TARGET="$TARGET_CONFIG_DIR/quickshell"
KITTY_TARGET="$TARGET_CONFIG_DIR/kitty"

# Logging utilities
log_info()    { echo -e "${C_BLUE}ℹ [INFO]${C_RESET} $*"; }
log_ok()      { echo -e "${C_GREEN}✔ [OK]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}⚠ [WARN]${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}✖ [ERROR]${C_RESET} $*" >&2; }
log_section() { echo -e "\n${C_BOLD}${C_MAGENTA}==> ${C_CYAN}$*${C_RESET}"; }

# Banner display
display_banner() {
    cat << "EOF"
  ██████╗ ██████╗ ███████╗ ██████╗  ██████╗ ██╗   ██╗███████╗███████╗███████╗
 ██╔════╝ ██╔══██╗██╔════╝██╔════╝ ██╔═══██╗██║   ██║╚══███╔╝╚══███╔╝██╔════╝
 ██║  ███╗██████╔╝█████╗  ██║  ███╗██║   ██║██║   ██║  ███╔╝   ███╔╝ █████╗  
 ██║   ██║██╔══██╗██╔══╝  ██║   ██║██║   ██║██║   ██║ ███╔╝   ███╔╝  ██╔══╝  
 ╚██████╔╝██║  ██║███████╗╚██████╔╝╚██████╔╝╚██████╔╝███████╗███████╗███████╗
  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝
                     ── S H E L L   E D I T I O N ──
EOF
    echo -e "${C_DIM}           Inspired by Caelestia Shell • Arch Linux & Hyprland${C_RESET}\n"
}

# Display CLI Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -i, --install      Run automated dependency check, installation, and symlinks setup
    -u, --update       Perform clean git pull, refresh symlinks, and reload running components
    -s, --info, --status Display shell status, dependency health check, and active shortcuts
    -l, --links        Re-apply symbolic links without reinstalling packages
    -h, --help         Show this help message and exit

If run without arguments, an interactive menu will be launched.
EOF
}

# Detect available AUR helper
detect_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        echo "paru"
    elif command -v yay >/dev/null 2>&1; then
        echo "yay"
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 1. Dependency Checks & Automatic Installation
# ------------------------------------------------------------------------------
check_dependencies() {
    log_section "Checking & Installing System Dependencies"

    local core_deps=("hyprland" "kitty" "matugen" "quickshell")
    local util_deps=("jq" "notify-send" "socat")
    local missing_packages=()

    echo -e "${C_BOLD}Core Packages:${C_RESET}"
    for dep in "${core_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local ver
            ver="$("$dep" --version 2>/dev/null | head -n1 || echo "installed")"
            printf "  ${C_GREEN}✔${C_RESET} %-14s ${C_DIM}(%s)${C_RESET}\n" "$dep" "$ver"
        else
            printf "  ${C_RED}✖${C_RESET} %-14s ${C_RED}[MISSING]${C_RESET}\n" "$dep"
            missing_packages+=("$dep")
        fi
    done

    # Wallpaper daemon detection (swww or awww)
    local wall_installed=false
    local wall_name=""
    if command -v swww >/dev/null 2>&1; then
        wall_installed=true
        wall_name="swww"
    elif command -v awww >/dev/null 2>&1; then
        wall_installed=true
        wall_name="awww"
    fi

    if [[ "$wall_installed" == true ]]; then
        local ver
        ver="$("$wall_name" --version 2>/dev/null | head -n1 || echo "installed")"
        printf "  ${C_GREEN}✔${C_RESET} %-14s ${C_DIM}(%s: %s)${C_RESET}\n" "swww/awww" "$wall_name" "$ver"
    else
        printf "  ${C_RED}✖${C_RESET} %-14s ${C_RED}[MISSING]${C_RESET}\n" "swww/awww"
        missing_packages+=("awww")
    fi

    echo -e "\n${C_BOLD}Utility Packages:${C_RESET}"
    for dep in "${util_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            printf "  ${C_GREEN}✔${C_RESET} %-14s ${C_DIM}(installed)${C_RESET}\n" "$dep"
        else
            printf "  ${C_YELLOW}⚠${C_RESET} %-14s ${C_YELLOW}[MISSING]${C_RESET}\n" "$dep"
            if [[ "$dep" == "notify-send" ]]; then
                missing_packages+=("libnotify")
            else
                missing_packages+=("$dep")
            fi
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_ok "All required dependencies are satisfied!"
        return 0
    fi

    log_section "Automatically Installing Missing Dependencies"
    echo -e "Packages to install: ${C_BOLD}${missing_packages[*]}${C_RESET}"
    
    local aur_helper
    aur_helper="$(detect_aur_helper)"

    if [[ -n "$aur_helper" ]]; then
        log_info "Installing automatically via $aur_helper (--noconfirm)..."
        "$aur_helper" -Sy --needed --noconfirm "${missing_packages[@]}"
        log_ok "Dependencies installed successfully."
    else
        log_info "No AUR helper found. Installing automatically via official pacman repos (--noconfirm)..."
        sudo pacman -Sy --needed --noconfirm "${missing_packages[@]}"
        log_ok "Dependencies installed successfully via pacman."
    fi
}

# ------------------------------------------------------------------------------
# 2. Safe Symbolic Link Creation
# ------------------------------------------------------------------------------
safe_symlink() {
    local source_path="$1"
    local target_path="$2"
    local description="$3"

    # If the target already correctly points to the source, nothing to do
    if [[ -L "$target_path" && "$(readlink -f "$target_path")" == "$(readlink -f "$source_path")" ]]; then
        printf "  ${C_GREEN}✔${C_RESET} %-26s ${C_DIM}Already linked${C_RESET}\n" "$description"
        return 0
    fi

    # Ensure parent directory of target exists
    mkdir -p "$(dirname "$target_path")"

    # If target exists and is a real file/dir or points elsewhere, back it up safely
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        local backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Existing path detected at $target_path. Creating backup at $backup_path"
        mv "$target_path" "$backup_path"
    fi

    ln -sfn "$source_path" "$target_path"
    printf "  ${C_GREEN}✔${C_RESET} %-26s ${C_CYAN}%s -> %s${C_RESET}\n" "$description" "$target_path" "$source_path"
}

setup_symlinks() {
    log_section "Configuring Symbolic Links"

    # Make scripts executable
    chmod +x "$SCRIPTS_SRC"/*.sh 2>/dev/null || true

    # Quickshell configuration link
    safe_symlink "$QUICKSHELL_SRC" "$QUICKSHELL_TARGET" "Quickshell Shell"

    # Hyprland colors link
    safe_symlink "$HYPR_SRC/colors.conf" "$HYPR_TARGET/colors.conf" "Hyprland Colors"

    # Kitty colors link
    safe_symlink "$KITTY_SRC/colors.conf" "$KITTY_TARGET/colors.conf" "Kitty Colors"

    # If awww is installed but swww is not in PATH, create compatibility link in ~/.local/bin
    if command -v awww >/dev/null 2>&1 && ! command -v swww >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$(which awww)" "$HOME/.local/bin/swww"
        if command -v awww-daemon >/dev/null 2>&1 && ! command -v swww-daemon >/dev/null 2>&1; then
            ln -sfn "$(which awww-daemon)" "$HOME/.local/bin/swww-daemon"
        fi
        log_ok "Created swww compatibility alias (~/.local/bin/swww -> $(which awww))."
    fi

    log_ok "All symbolic links created and validated."
}

# ------------------------------------------------------------------------------
# 3. Initialize Color Scheme
# ------------------------------------------------------------------------------
init_color_scheme() {
    log_section "Initializing Default Color Scheme (Matugen Dark Mode)"

    local test_color="#2563eb"
    if command -v matugen >/dev/null 2>&1; then
        if [[ -f "$SHELL_DIR/.wallpaper_path" && -f "$(cat "$SHELL_DIR/.wallpaper_path")" ]]; then
            local active_wall
            active_wall="$(cat "$SHELL_DIR/.wallpaper_path")"
            log_info "Refreshing colors from current wallpaper: $active_wall"
            "$SCRIPTS_SRC/wall-switch.sh" "$active_wall" || true
        else
            log_info "No previous wallpaper found. Generating base dark theme palette ($test_color)..."
            matugen -c "$MATUGEN_SRC/config.toml" color hex "$test_color" -m dark >/dev/null 2>&1 || true
            log_ok "Default color palette generated."
        fi
    else
        log_warn "Matugen not installed. Color generation skipped."
    fi
}

# ------------------------------------------------------------------------------
# 4. Installation Flow
# ------------------------------------------------------------------------------
run_install() {
    display_banner
    log_info "Starting gregouzze-shell setup..."
    check_dependencies
    setup_symlinks
    init_color_scheme

    log_section "Installation Completed Successfully! 🎉"
    echo -e "You can now test switching wallpapers dynamically at any time using:"
    echo -e "  ${C_BOLD}${C_CYAN}~/.config/gregouzze-shell/scripts/wall-switch.sh <path-to-image>${C_RESET}\n"
    echo -e "To reload Hyprland configs:"
    echo -e "  ${C_BOLD}hyprctl reload${C_RESET}\n"
}

# ------------------------------------------------------------------------------
# 5. Update Flow
# ------------------------------------------------------------------------------
run_update() {
    display_banner
    log_section "Updating gregouzze-shell via Git"

    cd "$SHELL_DIR"

    if [[ -d ".git" ]]; then
        log_info "Pulling latest changes from remote..."
        git pull --rebase || {
            log_error "git pull encountered conflicts or failed. Please resolve git state manually."
            exit 1
        }
        log_ok "Repository is up to date."
    else
        log_warn "Not a git repository. Skipping git pull."
    fi

    setup_symlinks

    # Re-apply wallpaper if recorded
    if [[ -f "$SHELL_DIR/.wallpaper_path" ]]; then
        local wall
        wall="$(cat "$SHELL_DIR/.wallpaper_path")"
        if [[ -f "$wall" ]]; then
            log_info "Re-applying wallpaper and updating palette: $wall"
            "$SCRIPTS_SRC/wall-switch.sh" "$wall" || true
        fi
    fi

    # Trigger live reloads
    if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl reload >/dev/null 2>&1 || true
        log_ok "Hyprland reloaded."
    fi

    pkill -SIGUSR1 kitty 2>/dev/null || true

    log_ok "gregouzze-shell has been updated and reloaded!"
}

# ------------------------------------------------------------------------------
# 6. Status & Information Flow (--info)
# ------------------------------------------------------------------------------
show_info() {
    display_banner
    log_section "gregouzze-shell Environment & Health Status"

    # Git details
    cd "$SHELL_DIR"
    if [[ -d ".git" ]]; then
        local branch commit commit_date
        branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
        commit="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
        commit_date="$(git log -1 --format=%cd --date=relative 2>/dev/null || echo "unknown")"
        echo -e "${C_BOLD}Repository Status:${C_RESET}"
        printf "  • Branch     : ${C_CYAN}%s${C_RESET}\n" "$branch"
        printf "  • Commit     : ${C_YELLOW}%s${C_RESET} (%s)\n" "$commit" "$commit_date"
        printf "  • Location   : %s\n" "$SHELL_DIR"
    fi

    echo ""
    echo -e "${C_BOLD}Active Configuration & Wallpapers:${C_RESET}"
    if [[ -f "$SHELL_DIR/.wallpaper_path" ]]; then
        printf "  • Active Wallpaper : ${C_GREEN}%s${C_RESET}\n" "$(cat "$SHELL_DIR/.wallpaper_path")"
    else
        printf "  • Active Wallpaper : ${C_DIM}None recorded (run wall-switch.sh)${C_RESET}\n"
    fi

    if [[ -f "$QUICKSHELL_SRC/colors.json" ]] && command -v jq >/dev/null 2>&1; then
        local primary surface
        primary="$(jq -r '.colors.primary // empty' "$QUICKSHELL_SRC/colors.json")"
        surface="$(jq -r '.colors.surface // empty' "$QUICKSHELL_SRC/colors.json")"
        printf "  • Color Mode       : ${C_BOLD}Dark (Material You)${C_RESET}\n"
        printf "  • Primary Accent   : %s\n" "$primary"
        printf "  • Surface Base     : %s\n" "$surface"
    fi

    echo ""
    echo -e "${C_BOLD}Dependencies Status:${C_RESET}"
    local binaries=("hyprctl" "quickshell" "matugen" "kitty" "jq" "notify-send")
    for bin in "${binaries[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            printf "  ${C_GREEN}✔${C_RESET} %-14s : ${C_DIM}%s${C_RESET}\n" "$bin" "$(which "$bin")"
        else
            printf "  ${C_RED}✖${C_RESET} %-14s : ${C_RED}NOT FOUND${C_RESET}\n" "$bin"
        fi
    done

    if command -v swww >/dev/null 2>&1; then
        printf "  ${C_GREEN}✔${C_RESET} %-14s : ${C_DIM}%s${C_RESET}\n" "swww" "$(which swww)"
    elif command -v awww >/dev/null 2>&1; then
        printf "  ${C_GREEN}✔${C_RESET} %-14s : ${C_DIM}%s (swww replacement)${C_RESET}\n" "awww" "$(which awww)"
    else
        printf "  ${C_RED}✖${C_RESET} %-14s : ${C_RED}NOT FOUND (swww / awww)${C_RESET}\n" "swww/awww"
    fi

    log_section "Default Keybindings Quick Reference"
    cat << "EOF"
  ┌───────────────────────┬─────────────────────────────────────────────────┐
  │ Keybinding            │ Action                                          │
  ├───────────────────────┼─────────────────────────────────────────────────┤
  │ Super + Return        │ Open Kitty Terminal                             │
  │ Super + Space         │ App Launcher (Quickshell / Rofi / Wofi)         │
  │ Super + W             │ Dynamic Wallpaper & Color Switcher              │
  │ Super + Q             │ Close focused window                            │
  │ Super + M             │ Exit Hyprland session                           │
  │ Super + F             │ Toggle Fullscreen                               │
  │ Super + V             │ Toggle Floating mode                            │
  │ Super + [H/J/K/L]     │ Focus Left / Down / Up / Right (Vim keys)       │
  │ Super + 1-9           │ Switch to Workspace 1-9                         │
  │ Super + Shift + 1-9   │ Move active window to Workspace 1-9             │
  └───────────────────────┴─────────────────────────────────────────────────┘
EOF
}

# ------------------------------------------------------------------------------
# 7. Interactive Menu
# ------------------------------------------------------------------------------
interactive_menu() {
    while true; do
        clear
        display_banner
        echo -e "${C_BOLD}Main Menu - Please choose an option:${C_RESET}\n"
        echo -e "  ${C_CYAN}1)${C_RESET} 📦 Full Installation (Dependencies + Symlinks + Palette)"
        echo -e "  ${C_CYAN}2)${C_RESET} 🔄 Update gregouzze-shell (Git Pull + Reapply + Reload)"
        echo -e "  ${C_CYAN}3)${C_RESET} 🔗 Re-apply Symbolic Links only"
        echo -e "  ${C_CYAN}4)${C_RESET} 🖼  Switch Wallpaper & Regenerate Colors"
        echo -e "  ${C_CYAN}5)${C_RESET} ℹ  Display Shell Status & Keybindings Info"
        echo -e "  ${C_CYAN}6)${C_RESET} 🚪 Exit"
        echo ""
        read -rp "Enter choice [1-6]: " choice

        case "$choice" in
            1)
                run_install
                read -rp "Press Enter to return to menu..."
                ;;
            2)
                run_update
                read -rp "Press Enter to return to menu..."
                ;;
            3)
                setup_symlinks
                read -rp "Press Enter to return to menu..."
                ;;
            4)
                echo ""
                read -rp "Enter full path to image file: " wall_input
                if [[ -n "$wall_input" ]]; then
                    "$SCRIPTS_SRC/wall-switch.sh" "$wall_input"
                else
                    log_warn "No wallpaper path entered."
                fi
                read -rp "Press Enter to return to menu..."
                ;;
            5)
                show_info
                read -rp "Press Enter to return to menu..."
                ;;
            6)
                echo -e "\nGoodbye! 👋"
                exit 0
                ;;
            *)
                log_error "Invalid option '$choice'. Please select between 1 and 6."
                sleep 1.5
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
main() {
    if [[ $# -eq 0 ]]; then
        interactive_menu
    else
        case "$1" in
            -i|--install)
                run_install
                ;;
            -u|--update)
                run_update
                ;;
            -s|--info|--status)
                show_info
                ;;
            -l|--links)
                setup_symlinks
                ;;
            -h|--help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi
}

main "$@"
