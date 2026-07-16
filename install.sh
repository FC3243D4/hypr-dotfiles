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

CONFIG_DIRS=("hypr" "matugen" "rofi" "waybar" "swaync" "wlogout" "quickshell")

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

# ─── Hyprland user preferences (primary display, workspaces, layout) ──────────
# Detects the primary display and asks for a couple of layout preferences,
# writing them into 01-UserDefaults.lua via hl.env(...). Moved here (out of
# Wallpaper-changer's own install-Linux.sh) since none of this is
# wallpaper-specific — it's general dotfiles configuration.

echo "=== Configuring Hyprland user preferences ==="

USERDEFAULTS_LUA="$CONFIG_HOME/hypr/UserConfigs/01-UserDefaults.lua"
STARTUPAPPS_LUA="$CONFIG_HOME/hypr/UserConfigs/Startup_Apps.lua"

_ensure_hl_env() {
    # $1 file, $2 hl.env variable name, $3 value
    local file="$1" varname="$2" value="$3"
    if grep -qE "^[[:space:]]*hl\.env\(\"$varname\"" "$file"; then
        sed -i -E "s|^([[:space:]]*)hl\.env\(\"$varname\", *\"[^\"]*\"\)|\1hl.env(\"$varname\", \"$value\")|" "$file"
        echo "$varname updated to $value in $file."
    else
        {
            echo ""
            echo "hl.env(\"$varname\", \"$value\")"
        } >> "$file"
        echo "$varname set to $value in $file (was missing, appended)."
    fi
}

if [ ! -f "$USERDEFAULTS_LUA" ]; then
    echo "$USERDEFAULTS_LUA not found — skipping Hyprland preference setup."
else
    # Primary display
    if ! command -v xrandr >/dev/null 2>&1; then
        echo "xrandr not found — skipping primary display detection."
    else
        primary_display=$(xrandr --query 2>/dev/null | awk '
            / connected/ {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^[0-9]+x[0-9]+\+0\+0$/) {
                        print $1
                        exit
                    }
                }
            }
        ')

        if [ -z "$primary_display" ]; then
            echo "Could not detect a display at position 0,0 — skipping primary display setup."
            echo "You may need to set this manually in $USERDEFAULTS_LUA."
        else
            xrandr --output "$primary_display" --primary 2>/dev/null
            _ensure_hl_env "$USERDEFAULTS_LUA" "PRIMARY_DISPLAY" "$primary_display"

            if [ -f "$STARTUPAPPS_LUA" ]; then
                if grep -qE '^\s*"xrandr --output \$PRIMARY_DISPLAY --primary",' "$STARTUPAPPS_LUA" 2>/dev/null; then
                    echo "Startup_Apps.lua already references \$PRIMARY_DISPLAY — leaving it as-is."
                else
                    sed -i 's|--"xrandr --output X --primary",|"xrandr --output $PRIMARY_DISPLAY --primary",|' "$STARTUPAPPS_LUA"
                    echo "Startup_Apps.lua updated to use \$PRIMARY_DISPLAY."
                fi
            else
                echo "$STARTUPAPPS_LUA not found — skipping."
            fi
        fi
    fi

    # Persistent workspaces
    read -p "How many persistent workspaces do you want? [default: 5] " workspaceCount
    [ -z "$workspaceCount" ] && workspaceCount=5
    until [[ "$workspaceCount" =~ ^[0-9]+$ ]] && [ "$workspaceCount" -gt 0 ]; do
        read -p "Please enter a positive whole number: " workspaceCount
    done
    _ensure_hl_env "$USERDEFAULTS_LUA" "PERSISTENT_WORKSPACES" "$workspaceCount"

    # Default layout
    layoutOptions=("master" "dwindle" "scrolling")
    echo "Choose your default Hyprland layout:"
    select defaultLayout in "${layoutOptions[@]}"; do
        if [ -n "$defaultLayout" ]; then
            echo "You chose: $defaultLayout"
            break
        else
            echo "Invalid choice, try again."
        fi
    done
    _ensure_hl_env "$USERDEFAULTS_LUA" "DEFAULT_LAYOUT" "$defaultLayout"
fi

echo ""

# ─── Waybar systemd service ────────────────────────────────────────────────────
# Installs a systemd user unit so waybar-git restarts automatically on crash,
# instead of relying on exec-once (which won't respawn a dead process). Any
# exec-once line launching waybar in the synced hypr configs is commented out
# so systemd is the sole launcher and we don't end up with duplicate instances.
# It also creates kill-waybar-kde.desktop inside ~/.config/autostart to kill
# the process when logging into KDE

echo "=== Installing waybar systemd service ==="

SYSTEMD_USER_DIR="$CONFIG_HOME/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

waybarBin="$(command -v waybar)"

if [ -z "$waybarBin" ]; then
    echo "waybar binary not found on PATH — skipping systemd service install."
else
    cat > "$SYSTEMD_USER_DIR/waybar.service" <<EOF
[Unit]
Description=Waybar
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=$waybarBin
ExecReload=/bin/kill -SIGUSR2 \$MAINPID
Restart=on-failure
RestartSec=1
StartLimitBurst=5
StartLimitIntervalSec=30
ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland

[Install]
WantedBy=graphical-session.target
EOF
    echo "Wrote $SYSTEMD_USER_DIR/waybar.service"

        cat > "$CONFIG_HOME/autostart/kill-waybar-kde.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Stop Waybar on KDE
Exec=systemctl --user stop waybar.service
OnlyShowIn=KDE;
X-KDE-autostart-phase=1
EOF
    echo "Wrote $CONFIG_HOME/autostart/kill-waybar-kde.desktop"

    systemctl --user daemon-reload
    systemctl --user enable --now waybar.service
    echo "waybar.service enabled and started."
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
    echo "  nwg-displays -n $workspaceCount -m $CONFIG_HOME/hypr/monitors.conf"
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

# ─── Hyprland dynamic-cursors plugin (hyprpm) ─────────────────────────────────
# Adds and enables VirtCode/hypr-dynamic-cursors via Hyprland's own plugin
# manager. hyprpm ships with Hyprland itself (not a separate package), but it
# compiles plugins against headers matching your exact installed Hyprland
# version, so this step is skipped (rather than guessed around) if hyprpm
# isn't there or the build fails — a stale/mismatched header set is a common
# cause and generally means Hyprland itself needs updating first.
#
# NOTE: enabling the plugin here only loads it into Hyprland; it doesn't add
# any `plugin { dynamic-cursors { ... } }` config block. Add that yourself in
# your Hyprland config if you want to customize it — see the plugin's README
# at https://github.com/VirtCode/hypr-dynamic-cursors for available options.

echo "=== Installing dynamic-cursors Hyprland plugin (hyprpm) ==="

DYNAMIC_CURSORS_REPO="https://github.com/VirtCode/hypr-dynamic-cursors"
DYNAMIC_CURSORS_PLUGIN="dynamic-cursors"

if ! command -v hyprpm &>/dev/null; then
    echo "hyprpm not found on PATH — skipping dynamic-cursors plugin install."
    echo "(hyprpm ships with Hyprland; make sure Hyprland itself is installed and up to date.)"
else
    if hyprpm list 2>/dev/null | grep -qi "$DYNAMIC_CURSORS_PLUGIN"; then
        echo "$DYNAMIC_CURSORS_PLUGIN is already added to hyprpm — updating instead of re-adding."
        hyprpm update || echo "Warning: hyprpm update failed. Continuing with the existing install."
    else
        echo "Adding $DYNAMIC_CURSORS_PLUGIN plugin from $DYNAMIC_CURSORS_REPO..."
        if ! hyprpm add "$DYNAMIC_CURSORS_REPO"; then
            echo "Error: hyprpm failed to add $DYNAMIC_CURSORS_PLUGIN."
            echo "This is usually a header/build-tool mismatch — make sure Hyprland is up to date"
            echo "and cmake/meson/ninja/cpio/pkg-config are installed, then try:"
            echo "  hyprpm add $DYNAMIC_CURSORS_REPO"
            echo "manually."
        fi
    fi

    if hyprpm list 2>/dev/null | grep -qi "$DYNAMIC_CURSORS_PLUGIN"; then
        if hyprpm enable "$DYNAMIC_CURSORS_PLUGIN"; then
            echo "$DYNAMIC_CURSORS_PLUGIN enabled."
            echo "Reload Hyprland (or run 'hyprctl reload') for the plugin to take effect."
        else
            echo "Error: failed to enable $DYNAMIC_CURSORS_PLUGIN. Try 'hyprpm enable $DYNAMIC_CURSORS_PLUGIN' manually."
        fi
    else
        echo "$DYNAMIC_CURSORS_PLUGIN was not found in hyprpm's plugin list after the add step — skipping enable."
    fi
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
    (cd "$WALLPAPER_CHANGER_DIR" && ./install-Linux.sh --install) || echo "Warning: Wallpaper-changer's install-Linux.sh exited with an error."
elif [ -n "$WALLPAPER_CHANGER_DIR" ]; then
    echo "Error: install-Linux.sh not found in $WALLPAPER_CHANGER_DIR — repo layout may have changed."
fi

echo ""

# ─── KDE autostart entry for awww-daemon ───────────────────────────────────────
# Creates the .desktop file for awww-daemon on KDE into  ~/.config/autostart so 
# it launches on login.

cat > "$CONFIG_HOME/autostart/awww-daemon.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=awww-daemon
Exec=awww-daemon --layer bottom
OnlyShowIn=KDE;
X-GNOME-Autostart-enabled=true
EOF

echo ""
echo "Install complete."
exit 0