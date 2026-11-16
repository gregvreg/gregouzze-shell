#!/usr/bin/env bash
# ==============================================================================
# install.sh — Installer, Updater & Manager for gregouzze-shell
# Modular Arch Linux / Hyprland Rice inspired by Caelestia Shell
# ==============================================================================

set -euo pipefail

# ── ANSI ──────────────────────────────────────────────────────────────────────
C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m"
C_BLUE="\033[1;34m"; C_GREEN="\033[1;32m"; C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"; C_MAGENTA="\033[1;35m"; C_CYAN="\033[1;36m"

log_info()    { echo -e "${C_BLUE}ℹ [INFO]${C_RESET} $*"; }
log_ok()      { echo -e "${C_GREEN}✔ [OK]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}⚠ [WARN]${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}✖ [ERROR]${C_RESET} $*" >&2; }
log_section() { echo -e "\n${C_BOLD}${C_MAGENTA}==> ${C_CYAN}$*${C_RESET}"; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

display_banner() {
    echo -e "${C_CYAN}"
    cat <<'EOF'
  ██████╗ ██████╗ ███████╗ ██████╗  ██████╗ ██╗   ██╗███████╗███████╗███████╗
 ██╔════╝ ██╔══██╗██╔════╝██╔════╝ ██╔═══██╗██║   ██║╚══███╔╝╚══███╔╝██╔════╝
 ██║  ███╗██████╔╝█████╗  ██║  ███╗██║   ██║██║   ██║  ███╔╝   ███╔╝ █████╗
 ██║   ██║██╔══██╗██╔══╝  ██║   ██║██║   ██║██║   ██║ ███╔╝   ███╔╝  ██╔══╝
 ╚██████╔╝██║  ██║███████╗╚██████╔╝╚██████╔╝╚██████╔╝███████╗███████╗███████╗
  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${C_RESET}"
    echo -e "${C_DIM}                ── S H E L L   E D I T I O N ──${C_RESET}"
    echo -e "${C_DIM}       Inspired by Caelestia Shell • Arch Linux & Hyprland${C_RESET}\n"
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [COMMAND]

Commands:
    install, -i     Install dependencies, create symlinks, apply initial theme
    update,  -u     Git pull, refresh symlinks, reload theme
    info,    -s     Display shell status, deps health, and keybinds
    links,   -l     Re-apply symbolic links only
    help,    -h     Show this help

Run without arguments for an interactive menu.
EOF
}

# ── Helpers ───────────────────────────────────────────────────────────────────
detect_aur_helper() {
    for helper in paru yay; do
        command -v "$helper" >/dev/null 2>&1 && { echo "$helper"; return; }
    done
    echo ""
}

is_installed() {
    pacman -Qi "$1" &>/dev/null
}

install_pkg() {
    local pkg="$1"
    if is_installed "$pkg"; then
        log_ok "$pkg already installed"
        return 0
    fi

    # Try official repos first
    if pacman -Si "$pkg" &>/dev/null; then
        log_info "Installing $pkg from official repos…"
        sudo pacman -S --noconfirm --needed "$pkg"
    else
        local aur; aur="$(detect_aur_helper)"
        if [[ -n "$aur" ]]; then
            log_info "Installing $pkg from AUR via $aur…"
            "$aur" -S --noconfirm --needed "$pkg"
        else
            log_warn "Cannot install $pkg — no AUR helper found. Install paru or yay first."
            return 1
        fi
    fi
}

safe_symlink() {
    local src="$1" dst="$2"

    if [[ -L "$dst" ]]; then
        local current; current="$(readlink -f "$dst")"
        if [[ "$current" == "$(realpath "$src")" ]]; then
            log_ok "Symlink OK: $dst → $src"
            return
        fi
        local backup="${dst}.bak.$(date +%s)"
        log_warn "Backing up existing symlink $dst → $backup"
        mv "$dst" "$backup"
    elif [[ -e "$dst" ]]; then
        local backup="${dst}.bak.$(date +%s)"
        log_warn "Backing up existing $dst → $backup"
        mv "$dst" "$backup"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    log_ok "Linked: $dst → $src"
}

# ==============================================================================
# INSTALL
# ==============================================================================
do_install() {
    log_section "Checking system"

    if [[ ! -f /etc/arch-release ]]; then
        log_warn "Not Arch Linux — package installation may fail. Continuing anyway…"
    fi

    log_section "Installing dependencies"

    local -a PACKAGES=(
        # Core compositor & shell
        hyprland
        quickshell-git
        # Theming
        matugen-bin
        swww
        # Terminal
        kitty
        # Notifications
        mako
        # Screenshot & clipboard
        grim
        slurp
        grimblast-git
        wl-clipboard
        # Utilities
        jq
        imagemagick
        brightnessctl
        playerctl
        # Lock screen
        hyprlock
        # Fonts
        ttf-jetbrains-mono-nerd
    )

    local failed=0
    for pkg in "${PACKAGES[@]}"; do
        if ! install_pkg "$pkg"; then
            failed=$((failed + 1))
        fi
    done

    if ((failed > 0)); then
        log_warn "$failed package(s) could not be installed. Install paru or yay, then run '$SHELL_DIR/install.sh install' again."
        log_warn "Proceeding with configuration so the installer can be completed after dependencies are ready."
    fi

    do_links

    log_section "Making scripts executable"
    chmod +x "$SHELL_DIR/scripts/"*.sh 2>/dev/null || true
    chmod +x "$SHELL_DIR/install.sh"
    log_ok "Scripts are executable."

    log_section "Creating wallpaper directory"
    mkdir -p "$HOME/Pictures/Wallpapers"
    log_ok "$HOME/Pictures/Wallpapers ready."

    log_section "Initial theme application"
    if [[ -f "$SHELL_DIR/assets/default_wallpaper.png" ]]; then
        log_info "Applying default wallpaper & generating initial theme…"
        bash "$SHELL_DIR/scripts/wall-switch.sh" "$SHELL_DIR/assets/default_wallpaper.png" || \
            log_warn "Initial theme application failed — is matugen installed?"
    else
        log_info "No default wallpaper found. Place images in ~/Pictures/Wallpapers and run:"
        echo -e "    ${C_BOLD}~/.config/gregouzze-shell/scripts/wall-switch.sh ~/Pictures/Wallpapers/your-image.png${C_RESET}"
    fi

    echo ""
    log_section "Installation complete!"
    echo -e "  ${C_GREEN}•${C_RESET} Log out and back in, or run: ${C_BOLD}hyprctl reload${C_RESET}"
    echo -e "  ${C_GREEN}•${C_RESET} Change wallpaper:  ${C_BOLD}SUPER + W${C_RESET}  (wallpaper selector)"
    echo -e "  ${C_GREEN}•${C_RESET} App launcher:      ${C_BOLD}SUPER + Space${C_RESET}"
    echo -e "  ${C_GREEN}•${C_RESET} Power menu:        ${C_BOLD}SUPER + Escape${C_RESET}"
    echo ""
}

# ==============================================================================
# SYMLINKS
# ==============================================================================
do_links() {
    log_section "Setting up symbolic links"

    # Native Hyprland Lua configurations need a Lua hook; a .conf source line
    # is ignored when the active entry point is hyprland.lua.
    if [[ -f "$CONFIG_DIR/hypr/hyprland.lua" ]]; then
        local entry="$CONFIG_DIR/hypr/hyprland.lua"
        local hook='dofile((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/gregouzze-shell/hypr/hyprland.lua")'
        if ! grep -qF 'gregouzze-shell/hypr/hyprland.lua' "$entry"; then
            printf '\n-- gregouzze-shell integration\n%s\n' "$hook" >> "$entry"
            log_ok "Added gregouzze-shell hook to $entry"
        else
            log_ok "Hyprland Lua entry point already loads gregouzze-shell"
        fi

        # Release bindings already assigned to the old launcher and close action.
        local lua_keys="$CONFIG_DIR/hypr/config/keybinds.lua"
        if [[ -f "$lua_keys" ]] && { grep -q 'serpantinum msg toggle launcher' "$lua_keys" || grep -q 'mainMod .. " + W", hl.dsp.window.close()' "$lua_keys"; }; then
            cp -n "$lua_keys" "${lua_keys}.gregouzze-backup"
            sed -i \
                -e '/serpantinum msg toggle launcher/d' \
                -e 's/mainMod \.\. " + W", hl\.dsp\.window\.close()/mainMod .. " + Q", hl.dsp.window.close()/' \
                "$lua_keys"
            log_ok "Freed Super+Space and Super+W in $lua_keys (backup saved)"
        fi
    elif [[ -d "$CONFIG_DIR/hypr" ]]; then
        # Standard Hyprland configuration: source our modular .conf file.
        local hypr_conf="$CONFIG_DIR/hypr/hyprland.conf"
        local source_line="source = ~/.config/gregouzze-shell/hypr/hyprland.conf"
        if [[ -f "$hypr_conf" ]]; then
            if ! grep -qF "$source_line" "$hypr_conf"; then
                log_info "Adding gregouzze-shell source to existing hyprland.conf"
                echo "" >> "$hypr_conf"
                echo "# gregouzze-shell — dynamic rice" >> "$hypr_conf"
                echo "$source_line" >> "$hypr_conf"
                log_ok "Source line added to $hypr_conf"
            else
                log_ok "hyprland.conf already sources gregouzze-shell"
            fi
        else
            safe_symlink "$SHELL_DIR/hypr/hyprland.conf" "$hypr_conf"
        fi
    else
        safe_symlink "$SHELL_DIR/hypr" "$CONFIG_DIR/hypr"
    fi

    # Kitty
    safe_symlink "$SHELL_DIR/kitty" "$CONFIG_DIR/kitty"

    # Quickshell
    safe_symlink "$SHELL_DIR/quickshell" "$CONFIG_DIR/quickshell"

    # Mako
    mkdir -p "$SHELL_DIR/mako"
    safe_symlink "$SHELL_DIR/mako" "$CONFIG_DIR/mako"

    log_ok "All symlinks configured."
}

# ==============================================================================
# UPDATE
# ==============================================================================
do_update() {
    log_section "Updating gregouzze-shell"

    cd "$SHELL_DIR"

    if [[ -d .git ]]; then
        log_info "Pulling latest changes…"
        git stash --include-untracked 2>/dev/null || true
        git pull --rebase --autostash 2>/dev/null || git pull
        log_ok "Repository updated."
    else
        log_warn "Not a git repo — skipping pull."
    fi

    do_links

    chmod +x "$SHELL_DIR/scripts/"*.sh 2>/dev/null || true

    # Re-apply current wallpaper theme
    if [[ -f "$SHELL_DIR/.wallpaper_path" ]]; then
        local wall; wall="$(cat "$SHELL_DIR/.wallpaper_path")"
        if [[ -f "$wall" ]]; then
            log_info "Re-applying theme for: $wall"
            bash "$SHELL_DIR/scripts/wall-switch.sh" "$wall" || true
        fi
    fi

    log_ok "Update complete!"
}

# ==============================================================================
# INFO / STATUS
# ==============================================================================
do_info() {
    log_section "gregouzze-shell Status"

    # Version
    cd "$SHELL_DIR"
    local version
    if [[ -d .git ]]; then
        version="$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    else
        version="local"
    fi
    echo -e "  ${C_BOLD}Version:${C_RESET}  $version"
    echo -e "  ${C_BOLD}Location:${C_RESET} $SHELL_DIR"

    # Current wallpaper
    if [[ -f "$SHELL_DIR/.wallpaper_path" ]]; then
        echo -e "  ${C_BOLD}Wallpaper:${C_RESET} $(cat "$SHELL_DIR/.wallpaper_path")"
    else
        echo -e "  ${C_BOLD}Wallpaper:${C_RESET} ${C_DIM}not set${C_RESET}"
    fi

    # Dependencies
    log_section "Dependency Health Check"
    local -a deps=(hyprland quickshell matugen swww kitty mako grim slurp jq hyprlock brightnessctl playerctl)
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "  ${C_GREEN}✔${C_RESET} $dep"
        else
            echo -e "  ${C_RED}✖${C_RESET} $dep ${C_DIM}(missing)${C_RESET}"
        fi
    done

    # Symlinks
    log_section "Symlink Status"
    local -a links=("$CONFIG_DIR/kitty" "$CONFIG_DIR/quickshell" "$CONFIG_DIR/mako")
    for link in "${links[@]}"; do
        if [[ -L "$link" ]]; then
            echo -e "  ${C_GREEN}✔${C_RESET} $link → $(readlink -f "$link")"
        elif [[ -e "$link" ]]; then
            echo -e "  ${C_YELLOW}⚠${C_RESET} $link exists but is not a symlink"
        else
            echo -e "  ${C_RED}✖${C_RESET} $link ${C_DIM}(not found)${C_RESET}"
        fi
    done

    # Keybinds
    log_section "Quick Reference — Keybinds"
    cat <<EOF
  SUPER + Return      Terminal (Kitty)
  SUPER + Space       Application Launcher
  SUPER + W           Wallpaper Selector
  SUPER + Escape      Power Menu
  SUPER + Q           Kill active window
  SUPER + F           Toggle fullscreen
  SUPER + V           Toggle floating
  SUPER + 1–0         Switch workspace
  SUPER + SHIFT + P   Screenshot (area)
  Print               Screenshot (full)
EOF
    echo ""
}

# ==============================================================================
# INTERACTIVE MENU
# ==============================================================================
interactive_menu() {
    display_banner
    echo -e "${C_BOLD}What would you like to do?${C_RESET}\n"
    echo "  1) Install      — Full dependency install + symlinks + initial theme"
    echo "  2) Update       — Git pull + refresh links + reload theme"
    echo "  3) Info          — Show status, deps, and keybinds"
    echo "  4) Symlinks     — Re-apply symbolic links only"
    echo "  5) Help         — Show CLI usage"
    echo "  0) Exit"
    echo ""
    read -rp "  Choose [0-5]: " choice

    case "$choice" in
        1) do_install ;;
        2) do_update ;;
        3) do_info ;;
        4) do_links ;;
        5) show_help ;;
        0) echo "Bye!"; exit 0 ;;
        *) log_error "Invalid choice."; exit 1 ;;
    esac
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================
main() {
    case "${1:-}" in
        install|-i|--install)  display_banner; do_install ;;
        update|-u|--update)    display_banner; do_update ;;
        info|-s|--info|--status|status) display_banner; do_info ;;
        links|-l|--links)      display_banner; do_links ;;
        help|-h|--help)        display_banner; show_help ;;
        "")                    interactive_menu ;;
        *)                     log_error "Unknown command: $1"; show_help; exit 1 ;;
    esac
}

main "$@"
