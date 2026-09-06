#!/usr/bin/env bash
# Update.sh
# Re-syncs config folders from the repo into ~/.config, picking up new/changed
# files without touching hypr/UserScripts or hypr/UserConfigs (your own
# customizations live there and shouldn't be overwritten on update).
#
# Unlike Install.sh, this does NOT run dependency checks, GPU env toggling,
# Hyprland preference setup, or any of the app-specific configuration steps
# (Spicetify, Vesktop, Wallpaper-changer, etc.) — it's just the config sync.
#
# Usage: ./Update.sh

set -uo pipefail

# ─── Resolve paths ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Same list as Install.sh — keep these in sync if you add/remove config dirs.
CONFIG_DIRS=("hypr" "matugen" "rofi" "waybar" "swaync" "wlogout" "quickshell")

echo "=== Updating configs ==="
mkdir -p "$CONFIG_HOME"

for dir in "${CONFIG_DIRS[@]}"; do
    src="$SCRIPT_DIR/$dir/"
    dest="$CONFIG_HOME/$dir"

    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        echo "Skipping $dir — not found in repo."
        continue
    fi

    if [ ! -e "$dest" ]; then
        echo "$dest doesn't exist yet — skipping (run Install.sh first)."
        continue
    fi

    rsync_args=(-a)

    if [ "$dir" = "hypr" ]; then
        rsync_args+=(--exclude "UserScripts" --exclude "UserConfigs")
    fi

    rsync "${rsync_args[@]}" "$src" "$dest/"
    echo "Updated $dest <- $src$([ "$dir" = "hypr" ] && echo " (excluding UserScripts/, UserConfigs/)")"
done

echo ""
read "Update dotfiles complete. Would you like to update Wallpaper Changer as well? [Y/n]"
echo ""
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    WALLPAPER_CHANGER_DIR="$(dirname "$SCRIPT_DIR")/Wallpaper-changer"
    echo "Updating WallpaperChanger's scripts"
    if [ -d "$WALLPAPER_CHANGER_DIR/.git" ]; then
        echo "Wallpaper-changer already cloned at $WALLPAPER_CHANGER_DIR — pulling latest."
        if ! git -C "$WALLPAPER_CHANGER_DIR" pull --ff-only; then
            echo "Warning: git pull failed (local changes or diverged history?). Skipping update, using existing checkout."
        fi
    elif ! git clone https://github.com/FC3243D4/Wallpaper-changer "$WALLPAPER_CHANGER_DIR"; then
        echo "Error: failed to clone Wallpaper-changer. Skipping install."
        WALLPAPER_CHANGER_DIR=""
    fi
    "$WALLPAPER_CHANGER_DIR/install-Linux.sh" --update-scripts
fi
exit 0
