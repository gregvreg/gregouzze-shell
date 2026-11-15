#!/usr/bin/env bash
# ==============================================================================
# wall-switch.sh - Wallpaper & Theme Switcher for gregouzze-shell
# Transitions wallpaper using swww and dynamically generates colors via matugen
# ==============================================================================

set -euo pipefail

# ANSI color codes for clean logging
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"

log_info()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

# Usage message
usage() {
    echo -e "${C_BOLD}Usage:${C_RESET} $(basename "$0") <path-to-wallpaper>"
    echo ""
    echo -e "${C_BOLD}Description:${C_RESET}"
    echo "    Applies the specified wallpaper using 'swww' with a smooth transition,"
    echo "    then updates the Material You color scheme using 'matugen'."
    echo ""
    echo -e "${C_BOLD}Example:${C_RESET}"
    echo "    $(basename "$0") ~/Pictures/wallpapers/neon-city.png"
    exit 1
}

# 1. Validate argument
if [[ $# -lt 1 || -z "${1:-}" ]]; then
    log_error "No wallpaper file specified."
    usage
fi

INPUT_WALLPAPER="$1"

# Resolve absolute path
if command -v realpath >/dev/null 2>&1; then
    WALLPAPER="$(realpath "$INPUT_WALLPAPER")"
else
    WALLPAPER="$(readlink -f "$INPUT_WALLPAPER")"
fi

# Check file existence
if [[ ! -f "$WALLPAPER" ]]; then
    log_error "Wallpaper file does not exist: $INPUT_WALLPAPER"
    exit 1
fi

log_info "Target wallpaper: ${C_BOLD}$WALLPAPER${C_RESET}"

# 2. Determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MATUGEN_CONFIG="$PROJECT_DIR/matugen/config.toml"

if [[ ! -f "$MATUGEN_CONFIG" ]]; then
    log_error "Matugen config file not found at: $MATUGEN_CONFIG"
    exit 1
fi

# 3. Transition wallpaper with swww
if command -v swww >/dev/null 2>&1; then
    # Ensure swww-daemon is running
    if ! swww query >/dev/null 2>&1; then
        log_info "Initializing swww-daemon..."
        swww-daemon &
        sleep 0.5
    fi

    log_info "Applying wallpaper transition via swww..."
    swww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-step 90 \
        --transition-fps 60 \
        --transition-duration 1.5

    log_ok "Wallpaper transition initiated."
else
    log_warn "'swww' binary not found in PATH. Skipping wallpaper transition."
fi

# 4. Generate color scheme with matugen
if command -v matugen >/dev/null 2>&1; then
    log_info "Generating Material You palette (dark mode) via matugen..."
    matugen -c "$MATUGEN_CONFIG" image "$WALLPAPER" -m dark --source-color-index 0
    log_ok "Palette generated and exported for Hyprland, Kitty, and Quickshell."
else
    log_error "'matugen' binary not found in PATH."
    exit 1
fi

log_ok "Theme update complete!"
