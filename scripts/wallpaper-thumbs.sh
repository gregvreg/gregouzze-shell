#!/usr/bin/env bash
# ==============================================================================
# wallpaper-thumbs.sh — Thumbnail Generator for gregouzze-shell Wallpaper Selector
# Scans a wallpapers directory, creates cached thumbnails, and emits a manifest.
# ==============================================================================

set -euo pipefail

C_RESET="\033[0m"; C_BOLD="\033[1m"
C_BLUE="\033[1;34m"; C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"; C_RED="\033[1;31m"

log_info()  { echo -e "${C_BLUE}ℹ${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}✔${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
log_error() { echo -e "${C_RED}✖${C_RESET} $*" >&2; }

# ── Defaults ──────────────────────────────────────────────────────────────────
WALL_DIR="${HOME}/Pictures/Wallpapers"
THUMB_SIZE="320x180"
CACHE_DIR="${HOME}/.cache/gregouzze-shell/thumbs"

usage() {
    cat <<EOF
${C_BOLD}Wallpaper Thumbnail Generator — gregouzze-shell${C_RESET}

USAGE: $(basename "$0") [OPTIONS] [wallpaper-directory]

OPTIONS:
    -s, --size <WxH>   Thumbnail dimensions (default: 320x180)
    -h, --help         Show this help

If no directory is given, defaults to ~/Pictures/Wallpapers.
Thumbnails are cached in ~/.cache/gregouzze-shell/thumbs/.
A wallpapers.json manifest is written to the cache directory.
EOF
    exit 0
}

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -s|--size) THUMB_SIZE="$2"; shift 2 ;;
        -*)        log_error "Unknown option: $1"; exit 1 ;;
        *)         WALL_DIR="$1"; shift ;;
    esac
done

WALL_DIR="$(realpath "$WALL_DIR" 2>/dev/null || echo "$WALL_DIR")"

if [[ ! -d "$WALL_DIR" ]]; then
    log_error "Directory not found: $WALL_DIR"
    exit 1
fi

mkdir -p "$CACHE_DIR"

# ── Detect ImageMagick ───────────────────────────────────────────────────────
CONVERT=""
if command -v magick >/dev/null 2>&1; then
    CONVERT="magick"
elif command -v convert >/dev/null 2>&1; then
    CONVERT="convert"
else
    log_error "ImageMagick not found. Install imagemagick."
    exit 1
fi

# ── Generate thumbnails ──────────────────────────────────────────────────────
count=0
skipped=0
MANIFEST="$CACHE_DIR/wallpapers.json"

# Start JSON array
echo "[" > "$MANIFEST"
first=true

shopt -s nullglob nocaseglob
for img in "$WALL_DIR"/*.{jpg,jpeg,png,webp,bmp}; do
    [[ ! -f "$img" ]] && continue

    # Unique thumbnail name from path hash
    hash="$(echo -n "$img" | md5sum | cut -d' ' -f1)"
    ext="${img##*.}"
    thumb="$CACHE_DIR/${hash}.${ext}"

    # Only regenerate if source is newer
    if [[ -f "$thumb" && "$thumb" -nt "$img" ]]; then
        ((skipped++))
    else
        "$CONVERT" "$img" -thumbnail "${THUMB_SIZE}^" \
            -gravity center -extent "$THUMB_SIZE" \
            "$thumb" 2>/dev/null && ((count++)) || log_warn "Failed: $(basename "$img")"
    fi

    # Append to manifest JSON
    if $first; then first=false; else echo "," >> "$MANIFEST"; fi
    cat >> "$MANIFEST" <<ENTRY
  {
    "path": "$img",
    "thumbnail": "$thumb",
    "name": "$(basename "$img")"
  }
ENTRY
done
shopt -u nullglob nocaseglob

echo "]" >> "$MANIFEST"

log_ok "Generated: ${count} thumbnails, skipped: ${skipped} (up-to-date)"
log_ok "Manifest:  ${MANIFEST}"
