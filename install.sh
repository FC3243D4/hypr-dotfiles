#!/usr/bin/env bash
# install.sh
# Entry point for installing hypr-dotfiles. Runs dependency checks/installation,
# then syncs configs into place.
#
# Usage: ./install.sh

set -uo pipefail

# ─── Resolve paths ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
export SUPPORT="$SCRIPT_DIR/installSupportScripts"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

if [ ! -d "$SUPPORT" ]; then
    echo "Error: expected support scripts at $SUPPORT but the directory doesn't exist."
    exit 1
fi

# ─── Dependency check ─────────────────────────────────────────────────────────

echo "=== Dependency check ==="
source "$SUPPORT/dependency_check.sh"
if [ $? -ne 0 ]; then
    echo "Dependency check failed. Aborting install."
    exit 1
fi
echo ""

# ─── Sync configs ──────────────────────────────────────────────────────────────
# Copies each top-level config folder into ~/.config via rsync, so re-running
# this script only transfers new/changed files instead of the whole tree.
# Existing content is preserved (no --delete), so anything you've added
# locally inside these config dirs won't be removed by a re-sync.
#
# A one-time backup is taken the first time a destination is touched, marked
# by a hidden .hypr-dotfiles-managed file dropped after a successful sync —
# on later runs the presence of that marker skips the backup step.
#
# ASSUMPTION: hypr/, matugen/, rofi/, waybar/, swaync/ map 1:1 to
# ~/.config/hypr, ~/.config/matugen, ~/.config/rofi, ~/.config/waybar,
# ~/.config/swaync. Confirm this matches what's actually inside those
# folders before relying on it.

CONFIG_DIRS=("hypr" "matugen" "rofi" "waybar" "swaync")

echo "=== Syncing configs ==="
mkdir -p "$CONFIG_HOME"

for dir in "${CONFIG_DIRS[@]}"; do
    src="$SCRIPT_DIR/$dir/"
    dest="$CONFIG_HOME/$dir"

    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        echo "Skipping $dir — not found in repo."
        continue
    fi

    if [ -L "$dest" ]; then
        echo "$dest is a symlink from a previous install method — removing it before syncing."
        rm "$dest"
    fi

    if [ -e "$dest" ] && [ ! -e "$dest/.hypr-dotfiles-managed" ]; then
        if [ -e "$dest.bak" ]; then
            echo "$dest exists (unmanaged) and $dest.bak already exists — leaving $dest alone. Resolve manually."
            continue
        fi
        echo "Backing up existing unmanaged $dest to $dest.bak"
        cp -a "$dest" "$dest.bak"
    fi

    mkdir -p "$dest"
    rsync -a "$src" "$dest/"
    touch "$dest/.hypr-dotfiles-managed"
    echo "Synced $dest <- $src"
done

echo ""

# ─── GPU detection / NVIDIA env toggle ─────────────────────────────────────────
# Detects whether an NVIDIA GPU is present and uncomments/comments the NVIDIA
# block in ENVariables.lua accordingly. Only touches the four lines in the
# "NVIDIA" section (LIBVA_DRIVER_NAME, __GLX_VENDOR_LIBRARY_NAME, NVD_BACKEND,
# GSK_RENDERER) — the "additional ENV's for nvidia, activate with care" block
# further down is left untouched since those are explicitly opt-in.

echo "=== Detecting GPU vendor ==="

_set_hl_env_state() {
    # $1 file, $2 hl.env variable name, $3 desired state ("true" = enabled/uncommented)
    local file="$1" varname="$2" enabled="$3"
    if [ "$enabled" = true ]; then
        sed -i -E "s/^([[:space:]]*)--([[:space:]]*hl\.env\(\"$varname\".*)/\1\2/" "$file"
    else
        sed -i -E "/^[[:space:]]*--[[:space:]]*hl\.env\(\"$varname\"/! s/^([[:space:]]*)(hl\.env\(\"$varname\".*)/\1--\2/" "$file"
    fi
}

envFile="$(find "$CONFIG_HOME/hypr" -name "ENVariables.lua" -print -quit 2>/dev/null)"

if [ -z "$envFile" ]; then
    echo "ENVariables.lua not found under $CONFIG_HOME/hypr — skipping GPU env toggle."
else
    hasNvidia=false
    if lspci -k | grep -E "VGA|3D" -A3 | grep -qi nvidia; then
        hasNvidia=true
    fi

    nvidiaVars=("LIBVA_DRIVER_NAME" "__GLX_VENDOR_LIBRARY_NAME" "NVD_BACKEND" "GSK_RENDERER")

    if [ "$hasNvidia" = true ]; then
        echo "NVIDIA GPU detected — enabling NVIDIA env block in $envFile"
        for v in "${nvidiaVars[@]}"; do
            _set_hl_env_state "$envFile" "$v" true
        done
    else
        echo "No NVIDIA GPU detected — disabling NVIDIA env block in $envFile"
        for v in "${nvidiaVars[@]}"; do
            _set_hl_env_state "$envFile" "$v" false
        done
    fi
fi

echo ""

# ─── Generate monitor/workspace config (nwg-displays) ─────────────────────────
# nwg-displays needs a live Hyprland session to query outputs over IPC — it
# can't run from a TTY before you've logged in at least once, and it has no
# KDE/Plasma backend (only sway, Hyprland, and Niri).

echo "=== Generating monitor config ==="

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "Hyprland session detected — launching nwg-displays."
    echo "Arrange your outputs in the window that opens, then click Apply."
    nwg-displays -m "$CONFIG_HOME/hypr/monitors.conf"
else
    echo "No active Hyprland session detected (HYPRLAND_INSTANCE_SIGNATURE not set)."
    echo "Skipping monitor config generation."
    echo "After logging into Hyprland, run this manually:"
    echo "  nwg-displays -m $CONFIG_HOME/hypr/monitors.conf"
fi

echo ""

# ─── Compile Breeze cursor theme (accurse) ─────────────────────────────────────
# Clones accurse to get its bundled theme assets, patches the Breeze theme's
# metadata.toml with your color/size overrides, compiles it, and installs the
# result to ~/.local/share/icons.

echo "=== Compiling Breeze cursor theme ==="

if ! command -v accurse &>/dev/null; then
    echo "accurse not found on PATH — skipping cursor theme compilation."
else
    ICONS_DIR="$HOME/.local/share/icons"
    mkdir -p "$ICONS_DIR"

    tmp="$(mktemp -d)"
    if git clone --depth 1 https://github.com/ATM-Jahid/accurse "$tmp/accurse"; then
        metadata="$tmp/accurse/assets/Breeze/metadata.toml"

        if [ ! -f "$metadata" ]; then
            echo "Error: $metadata not found — accurse's asset layout may have changed. Skipping."
        else
            sed -i 's/^[[:space:]]*new_substr[[:space:]]*=.*/new_substr = ["#000000", "#FFFFFF"]/' "$metadata"
            sed -i 's/^[[:space:]]*xcur_sizes[[:space:]]*=.*/xcur_sizes = [24, 32, 40, 48, 56, 64]/' "$metadata"

            if (cd "$tmp/accurse" && accurse assets/Breeze/metadata.toml); then
                if [ -d "$tmp/accurse/assets/AC-Breeze" ]; then
                    if [ -e "$ICONS_DIR/AC-Breeze" ]; then
                        echo "Removing previous $ICONS_DIR/AC-Breeze"
                        rm -rf "$ICONS_DIR/AC-Breeze"
                    fi
                    mv "$tmp/accurse/assets/AC-Breeze" "$ICONS_DIR/"
                    echo "Installed cursor theme to $ICONS_DIR/AC-Breeze"
                else
                    echo "Error: accurse ran but assets/AC-Breeze was not produced. Skipping install."
                fi
            else
                echo "Error: accurse failed to compile the Breeze theme. Skipping install."
            fi
        fi
    else
        echo "Error: failed to clone accurse. Skipping cursor theme compilation."
    fi
    rm -rf "$tmp"
fi

echo ""

# ─── Wallpaper-changer ─────────────────────────────────────────────────────────
# Clones (or updates) FC3243D4/Wallpaper-changer as a sibling of this repo,
# then runs its own installer.

echo "=== Installing Wallpaper-changer ==="

WALLPAPER_CHANGER_DIR="$(dirname "$SCRIPT_DIR")/Wallpaper-changer"

if [ -d "$WALLPAPER_CHANGER_DIR/.git" ]; then
    echo "Wallpaper-changer already cloned at $WALLPAPER_CHANGER_DIR — pulling latest."
    if ! git -C "$WALLPAPER_CHANGER_DIR" pull --ff-only; then
        echo "Warning: git pull failed (local changes or diverged history?). Skipping update, using existing checkout."
    fi
elif ! git clone https://github.com/FC3243D4/Wallpaper-changer "$WALLPAPER_CHANGER_DIR"; then
    echo "Error: failed to clone Wallpaper-changer. Skipping install."
    WALLPAPER_CHANGER_DIR=""
fi

if [ -n "$WALLPAPER_CHANGER_DIR" ] && [ -f "$WALLPAPER_CHANGER_DIR/install-Linux.sh" ]; then
    chmod +x "$WALLPAPER_CHANGER_DIR/install-Linux.sh"
    (cd "$WALLPAPER_CHANGER_DIR" && ./install-Linux.sh) || echo "Warning: Wallpaper-changer's install-Linux.sh exited with an error."
elif [ -n "$WALLPAPER_CHANGER_DIR" ]; then
    echo "Error: install-Linux.sh not found in $WALLPAPER_CHANGER_DIR — repo layout may have changed."
fi

echo ""

# ─── KDE autostart entry for awww-daemon ───────────────────────────────────────
# Clones (or updates) the .desktop file for awww-daemon on KDE into 
# ~/.config/autostart so it launches on login.
echo "=== Installing awww-daemon autostart entry for KDE ==="
rsync -a "awww-daemon.desktop" "$CONFIG_HOME/autostart/"

echo ""
echo "Install complete."
exit 0