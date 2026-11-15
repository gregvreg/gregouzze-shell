#!/usr/bin/env bash
# ==============================================================================
# wall-switch.sh - Wallpaper & Dynamic Theme Switcher for gregouzze-shell
# Transitions wallpaper via swww and triggers Matugen dynamic dark mode palette
# ==============================================================================

set -euo pipefail

# ANSI color codes for high-signal terminal output
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_CYAN="\033[1;36m"

log_info()  { echo -e "${C_BLUE}ℹ [INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}✔ [OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}⚠ [WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}✖ [ERROR]${C_RESET} $*" >&2; }

# Paths definition
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MATUGEN_CONFIG="$PROJECT_DIR/matugen/config.toml"
CURRENT_WALL_LINK="$PROJECT_DIR/current_wallpaper"
CURRENT_WALL_TXT="$PROJECT_DIR/.wallpaper_path"

# Default parameters
TRANSITION_TYPE="grow"
TRANSITION_FPS=60
TRANSITION_STEP=90
TRANSITION_DURATION=1.5
COLOR_MODE="dark" # Dark mode forced by default for code comfort

# Display usage information
usage() {
    echo -e "${C_BOLD}gregouzze-shell Wallpaper & Theme Switcher${C_RESET}"
    echo ""
    echo -e "${C_BOLD}USAGE:${C_RESET}"
    echo "    $(basename "$0") [OPTIONS] <path-to-wallpaper>"
    echo ""
    echo -e "${C_BOLD}OPTIONS:${C_RESET}"
    echo "    -t, --transition <type>   Transition effect: grow, fade, wipe, wave, outer, center (default: grow)"
    echo "    -m, --mode <mode>         Color scheme mode: dark, light (default: dark)"
    echo "    -d, --duration <seconds>  Transition duration in seconds (default: 1.5)"
    echo "    -h, --help                Show this help message and exit"
    echo ""
    echo -e "${C_BOLD}EXAMPLES:${C_RESET}"
    echo "    $(basename "$0") ~/Pictures/wallpapers/neon_city.png"
    echo "    $(basename "$0") --transition fade ~/Pictures/wallpapers/nordic.jpg"
    echo "    $(basename "$0") -t wave -d 2.0 /path/to/image.png"
    exit 0
}

# Parse command line flags
INPUT_WALLPAPER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -t|--transition)
            TRANSITION_TYPE="$2"
            shift 2
            ;;
        -m|--mode)
            COLOR_MODE="$2"
            shift 2
            ;;
        -d|--duration)
            TRANSITION_DURATION="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            if [[ -z "$INPUT_WALLPAPER" ]]; then
                INPUT_WALLPAPER="$1"
                shift
            else
                log_error "Multiple wallpaper paths provided: '$INPUT_WALLPAPER' and '$1'"
                exit 1
            fi
            ;;
    esac
done

# If no wallpaper argument was provided, try to restore current or prompt
if [[ -z "$INPUT_WALLPAPER" ]]; then
    if [[ -f "$CURRENT_WALL_TXT" ]]; then
        INPUT_WALLPAPER="$(cat "$CURRENT_WALL_TXT")"
        log_info "No wallpaper argument supplied. Re-applying current: $INPUT_WALLPAPER"
    else
        log_error "No wallpaper specified."
        echo ""
        usage
    fi
fi

# Resolve absolute path safely
if command -v realpath >/dev/null 2>&1; then
    WALLPAPER="$(realpath "$INPUT_WALLPAPER")"
else
    WALLPAPER="$(readlink -f "$INPUT_WALLPAPER")"
fi

# Check file existence and readability
if [[ ! -f "$WALLPAPER" ]]; then
    log_error "File not found: $INPUT_WALLPAPER"
    exit 1
fi

if [[ ! -r "$WALLPAPER" ]]; then
    log_error "File is not readable: $WALLPAPER"
    exit 1
fi

# Verify MIME type if 'file' command is present
if command -v file >/dev/null 2>&1; then
    MIME_TYPE="$(file --brief --mime-type "$WALLPAPER")"
    if [[ "$MIME_TYPE" != image/* ]]; then
        log_warn "File does not appear to be an image (MIME: $MIME_TYPE). Proceeding anyway..."
    fi
fi

log_info "Active Wallpaper: ${C_BOLD}$WALLPAPER${C_RESET}"

# ------------------------------------------------------------------------------
# 1. Wallpaper Transition with swww
# ------------------------------------------------------------------------------
if command -v swww >/dev/null 2>&1; then
    # Ensure swww-daemon is running and responding
    if ! swww query >/dev/null 2>&1; then
        log_info "Starting swww-daemon in background..."
        swww-daemon >/dev/null 2>&1 &
        
        # Poll up to 3 seconds for daemon socket readiness
        ready=false
        for _ in {1..30}; do
            if swww query >/dev/null 2>&1; then
                ready=true
                break
            fi
            sleep 0.1
        done

        if [ "$ready" = true ]; then
            log_ok "swww-daemon is initialized and responding."
        else
            log_warn "swww-daemon did not respond within timeout, attempting transition anyway."
        fi
    fi

    log_info "Applying wallpaper transition via swww (${TRANSITION_TYPE})..."
    swww img "$WALLPAPER" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-pos 0.5,0.5 \
        --transition-step "$TRANSITION_STEP" \
        --transition-fps "$TRANSITION_FPS" \
        --transition-duration "$TRANSITION_DURATION" 2>/dev/null || {
            log_warn "swww img returned a non-zero exit status; daemon might be starting up."
        }
    log_ok "Wallpaper transition applied successfully."
else
    log_warn "'swww' binary not found. Skipping live desktop wallpaper setting."
fi

# ------------------------------------------------------------------------------
# 2. Dynamic Palette Generation with Matugen
# ------------------------------------------------------------------------------
if [[ ! -f "$MATUGEN_CONFIG" ]]; then
    log_error "Matugen configuration not found: $MATUGEN_CONFIG"
    exit 1
fi

if command -v matugen >/dev/null 2>&1; then
    log_info "Extracting Material You palette (mode: ${COLOR_MODE}) via Matugen..."
    matugen -c "$MATUGEN_CONFIG" image "$WALLPAPER" \
        -m "$COLOR_MODE" \
        --source-color-index 0

    log_ok "Templates generated: Hyprland, Kitty, and Quickshell."
else
    log_error "'matugen' binary not found. Please install matugen."
    exit 1
fi

# ------------------------------------------------------------------------------
# 3. Store Current Wallpaper Path & Symlink
# ------------------------------------------------------------------------------
echo "$WALLPAPER" > "$CURRENT_WALL_TXT"
ln -sfn "$WALLPAPER" "$CURRENT_WALL_LINK"

# ------------------------------------------------------------------------------
# 4. Trigger Live App Reloads
# ------------------------------------------------------------------------------
# Hyprland reload
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Kitty reload
pkill -SIGUSR1 kitty 2>/dev/null || true

# Quickshell IPC reload notification if running
if command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call theme-changed 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. Desktop Notification
# ------------------------------------------------------------------------------
if command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "gregouzze-shell" \
        -i "$WALLPAPER" \
        -t 3000 \
        "Theme Updated" \
        "Wallpaper & Material You dark palette successfully applied." 2>/dev/null || true
fi

log_ok "${C_CYAN}Theme synchronization complete!${C_RESET}"
