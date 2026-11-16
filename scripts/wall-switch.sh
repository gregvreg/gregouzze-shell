#!/usr/bin/env bash
# ==============================================================================
# wall-switch.sh — Wallpaper & Dynamic Theme Switcher for gregouzze-shell
# Transitions wallpaper via swww, generates Material You palette via Matugen,
# and hot-reloads Hyprland, Kitty, Quickshell, and Mako.
# ==============================================================================

set -euo pipefail

# ── ANSI helpers ──────────────────────────────────────────────────────────────
C_RESET="\033[0m"; C_BOLD="\033[1m"
C_BLUE="\033[1;34m"; C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"; C_RED="\033[1;31m"; C_CYAN="\033[1;36m"

log_info()  { echo -e "${C_BLUE}ℹ [INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}✔ [OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}⚠ [WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}✖ [ERROR]${C_RESET} $*" >&2; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MATUGEN_CONFIG="$PROJECT_DIR/matugen/config.toml"
CURRENT_WALL_LINK="$PROJECT_DIR/current_wallpaper"
CURRENT_WALL_TXT="$PROJECT_DIR/.wallpaper_path"

# ── Defaults ──────────────────────────────────────────────────────────────────
TRANSITION_TYPE="grow"
TRANSITION_FPS=60
TRANSITION_STEP=90
TRANSITION_DURATION=1.5
COLOR_MODE="dark"

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${C_BOLD}gregouzze-shell — Wallpaper & Theme Switcher${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    $(basename "$0") [OPTIONS] <path-to-wallpaper>

${C_BOLD}OPTIONS:${C_RESET}
    -t, --transition <type>   grow | fade | wipe | wave | outer | center (default: grow)
    -m, --mode <mode>         dark | light (default: dark)
    -d, --duration <seconds>  Transition duration (default: 1.5)
    -h, --help                Show this help

${C_BOLD}EXAMPLES:${C_RESET}
    $(basename "$0") ~/Pictures/Wallpapers/neon.png
    $(basename "$0") -t fade -d 2.0 ~/Pictures/Wallpapers/nordic.jpg
EOF
    exit 0
}

# ── Parse arguments ───────────────────────────────────────────────────────────
INPUT_WALLPAPER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)      usage ;;
        -t|--transition) TRANSITION_TYPE="$2"; shift 2 ;;
        -m|--mode)       COLOR_MODE="$2";      shift 2 ;;
        -d|--duration)   TRANSITION_DURATION="$2"; shift 2 ;;
        -*)              log_error "Unknown option: $1"; exit 1 ;;
        *)
            if [[ -z "$INPUT_WALLPAPER" ]]; then
                INPUT_WALLPAPER="$1"; shift
            else
                log_error "Multiple wallpaper paths provided."; exit 1
            fi ;;
    esac
done

# Fall back to previously saved wallpaper
if [[ -z "$INPUT_WALLPAPER" ]]; then
    if [[ -f "$CURRENT_WALL_TXT" ]]; then
        INPUT_WALLPAPER="$(cat "$CURRENT_WALL_TXT")"
        log_info "Re-applying saved wallpaper: $INPUT_WALLPAPER"
    else
        log_error "No wallpaper specified."; echo; usage
    fi
fi

# Resolve and validate
WALLPAPER="$(realpath "$INPUT_WALLPAPER" 2>/dev/null || readlink -f "$INPUT_WALLPAPER")"

[[ ! -f "$WALLPAPER" ]] && { log_error "File not found: $INPUT_WALLPAPER"; exit 1; }
[[ ! -r "$WALLPAPER" ]] && { log_error "File not readable: $WALLPAPER"; exit 1; }

if command -v file >/dev/null 2>&1; then
    MIME="$(file --brief --mime-type "$WALLPAPER")"
    [[ "$MIME" != image/* ]] && log_warn "MIME type is '$MIME' — proceeding anyway."
fi

log_info "Wallpaper: ${C_BOLD}$WALLPAPER${C_RESET}"

# ── 1. swww / awww transition ────────────────────────────────────────────────
SWWW=""
if command -v swww >/dev/null 2>&1; then SWWW=swww
elif command -v awww >/dev/null 2>&1; then SWWW=awww; fi

if [[ -n "$SWWW" ]]; then
    # Ensure daemon is running
    if ! "$SWWW" query >/dev/null 2>&1; then
        log_info "Starting ${SWWW}-daemon…"
        "${SWWW}-daemon" >/dev/null 2>&1 &
        for _ in {1..30}; do
            "$SWWW" query >/dev/null 2>&1 && break
            sleep 0.1
        done
    fi

    log_info "Applying transition (${TRANSITION_TYPE})…"
    "$SWWW" img "$WALLPAPER" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-pos 0.5,0.5 \
        --transition-step "$TRANSITION_STEP" \
        --transition-fps "$TRANSITION_FPS" \
        --transition-duration "$TRANSITION_DURATION" 2>/dev/null || \
        log_warn "$SWWW img returned non-zero; daemon may still be initialising."
    log_ok "Wallpaper transition applied."
else
    log_warn "Neither swww nor awww found — skipping wallpaper display."
fi

# ── 2. Matugen palette generation ────────────────────────────────────────────
if [[ ! -f "$MATUGEN_CONFIG" ]]; then
    log_error "Matugen config missing: $MATUGEN_CONFIG"; exit 1
fi

if command -v matugen >/dev/null 2>&1; then
    log_info "Generating Material You palette (mode: ${COLOR_MODE})…"
    matugen -c "$MATUGEN_CONFIG" image "$WALLPAPER" \
        -m "$COLOR_MODE" --source-color-index 0
    log_ok "Templates rendered: Hyprland, Kitty, Quickshell, Mako."
else
    log_error "'matugen' not found. Install it first."; exit 1
fi

# ── 3. Persist current wallpaper path ────────────────────────────────────────
echo "$WALLPAPER" > "$CURRENT_WALL_TXT"
ln -sfn "$WALLPAPER" "$CURRENT_WALL_LINK"

# ── 4. Hot-reload running applications ───────────────────────────────────────
# Hyprland
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Kitty
pkill -SIGUSR1 kitty 2>/dev/null || true

# Mako
pkill -SIGUSR1 mako 2>/dev/null || true
command -v makoctl >/dev/null 2>&1 && makoctl reload 2>/dev/null || true

# Quickshell IPC
command -v quickshell >/dev/null 2>&1 && \
    quickshell ipc call gregouzze themeChanged 2>/dev/null || true

# ── 5. Desktop notification ──────────────────────────────────────────────────
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "gregouzze-shell" -i "$WALLPAPER" -t 3000 \
        "Theme Updated" \
        "Wallpaper & Material You ${COLOR_MODE} palette applied." 2>/dev/null || true
fi

log_ok "${C_CYAN}Theme synchronisation complete!${C_RESET}"
