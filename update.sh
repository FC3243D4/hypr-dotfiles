#!/usr/bin/env bash
# update.sh
# Re-syncs config folders from the repo into ~/.config, picking up new/changed
# files without touching hypr/UserScripts or hypr/UserConfigs (your own
# customizations live there and shouldn't be overwritten on update).
#
# Unlike install.sh, this does NOT run dependency checks, GPU env toggling,
# Hyprland preference setup, or any of the app-specific configuration steps
# (Spicetify, Vesktop, Wallpaper-changer, etc.) — it's just the config sync.
#
# Usage: ./update.sh

set -uo pipefail

# ─── Resolve paths ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Same list as install.sh — keep these in sync if you add/remove config dirs.
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
        echo "$dest doesn't exist yet — skipping (run install.sh first)."
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
echo "Update complete."
exit 0
