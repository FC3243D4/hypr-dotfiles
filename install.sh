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
        # Value may be a quoted string (hl.env("X", "y")) or a bare
        # Lua literal like a number (hl.env("X", 10)) - match either.
        if sed -i -E "s|^([[:space:]]*)hl\.env\(\"$varname\", *\"?[^\"()]*\"?\)|\1hl.env(\"$varname\", \"$value\")|" "$file" \
            && grep -qE "^[[:space:]]*hl\.env\(\"$varname\", *\"$value\"\)" "$file"; then
            echo "$varname updated to $value in $file."
        else
            echo "$varname: failed to update in $file (unexpected existing format) — please check manually." >&2
        fi
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
        mapfile -t connected_displays < <(xrandr --query 2>/dev/null | awk '/ connected/ {print $1}')

        if [ "${#connected_displays[@]}" -eq 0 ]; then
            echo "No connected displays detected via xrandr — skipping primary display setup."
            echo "You may need to set this manually in $USERDEFAULTS_LUA."
        else
            echo "Choose your primary display:"
            select primary_display in "${connected_displays[@]}"; do
                if [ -n "$primary_display" ]; then
                    echo "You chose: $primary_display"
                    break
                else
                    echo "Invalid choice, try again."
                fi
            done

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

    # Default editor — detect what's actually installed and offer only those,
    # always including nano (a tracked core dependency, so it should already
    # be installed by this point) as the guaranteed fallback/default choice.
    # Uses a plain read loop rather than `select`: bash's `select` has
    # documented behavior where pressing Enter with no input just redisplays
    # the menu without ever running the loop body, so there's no way to make
    # empty input mean "use the default" with `select` — only a manual
    # read-based prompt supports that.
    editorCandidates=("nano" "vim" "nvim" "code" "micro" "emacs" "hx" "kate" "gedit")
    editorOptions=()
    for candidate in "${editorCandidates[@]}"; do
        command -v "$candidate" &>/dev/null && editorOptions+=("$candidate")
    done
    if ! printf '%s\n' "${editorOptions[@]}" | grep -qx "nano"; then
        editorOptions=("nano" "${editorOptions[@]}")
    fi

    echo "Choose your default editor:"
    for i in "${!editorOptions[@]}"; do
        printf '%d) %s\n' "$((i + 1))" "${editorOptions[$i]}"
    done
    defaultEditor=""
    while [ -z "$defaultEditor" ]; do
        read -p "Enter a number [default: nano]: " editorChoice
        if [ -z "$editorChoice" ]; then
            defaultEditor="nano"
            echo "No selection — defaulting to nano."
        elif [[ "$editorChoice" =~ ^[0-9]+$ ]] && [ "$editorChoice" -ge 1 ] && [ "$editorChoice" -le "${#editorOptions[@]}" ]; then
            defaultEditor="${editorOptions[$((editorChoice - 1))]}"
            echo "You chose: $defaultEditor"
        else
            echo "Invalid choice, try again (or press Enter for nano)."
        fi
    done
    _ensure_hl_env "$USERDEFAULTS_LUA" "EDITOR" "$defaultEditor"
fi

echo ""

# ─── Waybar layout selection ───────────────────────────────────────────────────
# Waybar's active config/style are chosen via symlinks (config -> ./configs/X,
# style.css -> ./style/Y) rather than a single static file, so multiple named
# layouts can sit side by side and switching is just repointing the symlink.
# The configs/ and style/ directories hold many more (JaKooLit's stock
# options, kept around to browse/copy from) but only these 3 "blessed"
# layouts are offered here to keep the prompt short.

echo "=== Configuring Waybar layout ==="

WAYBAR_DIR="$CONFIG_HOME/waybar"
WAYBAR_CONFIGS_DIR="$WAYBAR_DIR/configs"

if [ ! -d "$WAYBAR_CONFIGS_DIR" ]; then
    echo "$WAYBAR_CONFIGS_DIR not found — skipping Waybar layout selection."
else
    waybarLayoutLabels=(
        "Desktop default"
        "Laptop default"
        "Desktop default (primary display only)"
    )
    waybarLayoutFiles=(
        "[TOP] fc3243d4"
        "[TOP] fc3243d4-laptop"
        "[TOP] fc3243d4-primary-display-only"
    )

    echo "Choose your Waybar layout:"
    select waybarLayoutChoice in "${waybarLayoutLabels[@]}"; do
        if [ -n "$waybarLayoutChoice" ]; then
            waybarLayoutFile="${waybarLayoutFiles[$((REPLY - 1))]}"
            echo "You chose: $waybarLayoutChoice"
            break
        else
            echo "Invalid choice, try again."
        fi
    done

    if [ ! -f "$WAYBAR_CONFIGS_DIR/$waybarLayoutFile" ]; then
        echo "Error: '$WAYBAR_CONFIGS_DIR/$waybarLayoutFile' not found — repo layout may have"
        echo "changed. Leaving the existing config symlink untouched."
    else
        ln -sf "./configs/$waybarLayoutFile" "$WAYBAR_DIR/config"
        echo "Linked $WAYBAR_DIR/config -> ./configs/$waybarLayoutFile"
    fi
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
    nwg-displays -n "${workspaceCount:-5}" -m "$CONFIG_HOME/hypr/monitors.conf"
    nwg-displays -n ${workspaceCount:-5} -w "$CONFIG_HOME/hypr/workspaces.conf"
else
    echo "No active Hyprland session detected (HYPRLAND_INSTANCE_SIGNATURE not set)."
    echo "Skipping monitor config generation."
    echo "After logging into Hyprland, run this manually:"
    echo "  nwg-displays -m $CONFIG_HOME/hypr/monitors.conf"
    echo "  nwg-displays -n ${workspaceCount:-5} -w $CONFIG_HOME/hypr/workspaces.conf"
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

# ─── Configure Spicetify (Spotify theming) ─────────────────────────────────────
# One-time setup so matugen-driven Spotify theming works right after install:
# backs up/patches the Spotify client, makes sure the theme used by the
# matugen spicetify template is present, points config-xpui.ini at it, and
# applies it.
#
# ASSUMPTION: targets the "Sleek" spicetify theme, matching the
# InioX/matugen-themes spicetify.ini template. If you use a different theme,
# change SPICETIFY_THEME below and make sure your matugen [templates.spotify]
# output_path/color keys match that theme instead.
#
# NOTE: this does NOT add the [templates.spotify] entry to matugen's own
# config.toml — nothing in this codebase manages matugen's config.toml, so
# that stays a manual step (see the reminder this section prints below).

echo "=== Configuring Spicetify ==="

SPICETIFY_THEME="Sleek"
SPICETIFY_THEMES_DIR="$CONFIG_HOME/spicetify/Themes"
SPICETIFY_CONFIG="$CONFIG_HOME/spicetify/config-xpui.ini"

_ensure_ini_kv() {
    # $1 file, $2 key, $3 value — updates an existing "key = ..." line
    # anywhere in the file, or appends "key = value" if the key isn't
    # present at all (defensive fallback; spicetify's own config-xpui.ini
    # normally already has these keys after `spicetify backup apply`).
    # Verifies the write actually landed rather than assuming success.
    local file="$1" key="$2" value="$3"
    if [ ! -f "$file" ]; then
        echo "$file not found — skipping $key update." >&2
        return 1
    fi
    if grep -qE "^[[:space:]]*$key[[:space:]]*=" "$file"; then
        sed -i -E "s|^([[:space:]]*)$key[[:space:]]*=.*|\1$key = $value|" "$file"
    else
        echo "$key = $value" >> "$file"
    fi
    if grep -qE "^[[:space:]]*$key[[:space:]]*=[[:space:]]*$value[[:space:]]*\$" "$file"; then
        echo "$key set to $value in $file."
    else
        echo "$key: failed to verify update in $file — please check manually." >&2
    fi
}

if ! command -v spicetify &>/dev/null; then
    echo "spicetify not found on PATH — skipping Spicetify configuration."
elif ! command -v spotify &>/dev/null \
    && [ ! -d "/opt/spotify" ] \
    && ! flatpak info com.spotify.Client &>/dev/null 2>&1; then
    # Best-effort only — won't catch every install method (snap, AUR
    # spotify-launcher wrappers, etc.). If you know Spotify is installed and
    # this still skips, just run the commands below manually instead.
    echo "Spotify client not detected — skipping Spicetify configuration."
    echo "Install Spotify first, then run manually: spicetify backup apply && spicetify apply"
else
    if pgrep -x spotify &>/dev/null; then
        echo "Spotify is currently running — spicetify needs it closed to patch safely."
        echo "Close Spotify, then run manually:"
        echo "  spicetify backup apply"
    else
        echo "Running spicetify backup apply..."
        if ! spicetify backup apply; then
            echo "Warning: 'spicetify backup apply' failed. Skipping the rest of Spicetify setup."
            echo "Run it manually once Spotify/spicetify are in a known-good state."
        else
            if [ -d "$SPICETIFY_THEMES_DIR/$SPICETIFY_THEME" ]; then
                echo "$SPICETIFY_THEME theme already present at $SPICETIFY_THEMES_DIR/$SPICETIFY_THEME."
            else
                echo "Fetching $SPICETIFY_THEME theme from spicetify/spicetify-themes..."
                tmp="$(mktemp -d)"
                if git clone --depth 1 https://github.com/spicetify/spicetify-themes "$tmp/spicetify-themes"; then
                    if [ -d "$tmp/spicetify-themes/$SPICETIFY_THEME" ]; then
                        mkdir -p "$SPICETIFY_THEMES_DIR"
                        cp -r "$tmp/spicetify-themes/$SPICETIFY_THEME" "$SPICETIFY_THEMES_DIR/"
                        echo "Installed $SPICETIFY_THEME theme to $SPICETIFY_THEMES_DIR/$SPICETIFY_THEME."
                    else
                        echo "Error: $SPICETIFY_THEME not found in spicetify-themes repo — repo layout may have changed."
                    fi
                else
                    echo "Error: failed to clone spicetify-themes. Skipping theme install."
                fi
                rm -rf "$tmp"
            fi

            _ensure_ini_kv "$SPICETIFY_CONFIG" "current_theme" "$SPICETIFY_THEME"
            _ensure_ini_kv "$SPICETIFY_CONFIG" "color_scheme" "matugen"

            echo ""
            echo "Reminder: add matugen's [templates.spotify] entry to your config.toml if you"
            echo "haven't already (input_path = your spicetify color.ini template, output_path ="
            echo "'$SPICETIFY_THEMES_DIR/$SPICETIFY_THEME/color.ini'), then run matugen once to"
            echo "generate color.ini."

            if [ -f "$SPICETIFY_THEMES_DIR/$SPICETIFY_THEME/color.ini" ]; then
                echo "Applying spicetify..."
                if ! spicetify apply; then
                    echo "Warning: 'spicetify apply' failed. Try running it manually after checking the errors above."
                else
                    echo "Spicetify applied successfully."
                fi
            else
                echo "color.ini not found yet at $SPICETIFY_THEMES_DIR/$SPICETIFY_THEME/color.ini —"
                echo "run matugen once (or wait for your next wallpaper change), then run 'spicetify apply' manually."
            fi
        fi
    fi
fi

# ─── Configure Vesktop (Midnight Discord theme) ────────────────────────────────
# One-time setup so the matugen-driven Midnight Discord theme works right after
# install: makes sure the themes directory exists, and best-effort enables the
# theme inside Vencord's own settings.json.
#
# NOTE: this does NOT add the [templates.vesktop] entry to matugen's own
# config.toml — nothing in this codebase manages matugen's config.toml, so
# that stays a manual step (see the reminder this section prints below).
#
# UNVERIFIED: the settings.json "enabledThemes" array patch below assumes
# Vencord's current settings schema. If Vencord changes this schema, or if
# your Vesktop version differs, the theme may not actually enable — check
# manually via Vesktop settings → Vencord → Themes if it doesn't take effect.

echo "=== Configuring Vesktop (Midnight Discord theme) ==="

if flatpak info dev.vencord.Vesktop &>/dev/null 2>&1; then
    VESKTOP_CONFIG_DIR="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    echo "Detected Flatpak Vesktop — using $VESKTOP_CONFIG_DIR."
else
    VESKTOP_CONFIG_DIR="$CONFIG_HOME/vesktop"
fi
VESKTOP_THEMES_DIR="$VESKTOP_CONFIG_DIR/themes"
VESKTOP_SETTINGS="$VESKTOP_CONFIG_DIR/settings.json"
VESKTOP_THEME_FILE="midnight-discord.css"

if ! command -v vesktop &>/dev/null \
    && ! flatpak info dev.vencord.Vesktop &>/dev/null 2>&1 \
    && [ ! -d "/opt/Vesktop" ]; then
    # Best-effort only — won't catch every install method (AppImage without
    # desktop integration, etc.). If you know Vesktop is installed and this
    # still skips, just create the themes dir and enable the theme manually.
    echo "Vesktop not detected — skipping Vesktop configuration."
    echo "Install Vesktop first (see https://vesktop.vencord.dev), then re-run this section."
else
    mkdir -p "$VESKTOP_THEMES_DIR"
    echo "Ensured themes directory exists: $VESKTOP_THEMES_DIR"

    echo ""
    echo "Reminder: add matugen's [templates.vesktop] entry to your config.toml if you"
    echo "haven't already (input_path = your midnight-discord.css template, output_path ="
    echo "'$VESKTOP_THEMES_DIR/$VESKTOP_THEME_FILE'), then run matugen once to generate it."
    echo "IMPORTANT: enable dark mode in Discord's own appearance settings — the"
    echo "Midnight theme expects it and won't look right without it (this can't be"
    echo "scripted; it's stored in Discord's own local app state, not a config file)."

    if [ -f "$VESKTOP_SETTINGS" ]; then
        if command -v jq &>/dev/null; then
            tmp_settings="$(mktemp)"
            if jq --arg theme "$VESKTOP_THEME_FILE" \
                '.enabledThemes = ((.enabledThemes // []) + [$theme] | unique)' \
                "$VESKTOP_SETTINGS" > "$tmp_settings" \
                && [ -s "$tmp_settings" ] \
                && jq -e . "$tmp_settings" &>/dev/null; then
                mv "$tmp_settings" "$VESKTOP_SETTINGS"
                echo "Enabled $VESKTOP_THEME_FILE in $VESKTOP_SETTINGS."
            else
                rm -f "$tmp_settings"
                echo "Warning: failed to update $VESKTOP_SETTINGS via jq — leaving it untouched."
                echo "Enable the theme manually: Vesktop settings → Vencord → Themes → $VESKTOP_THEME_FILE"
            fi
        else
            echo "jq not found — can't auto-enable the theme."
            echo "Enable it manually: Vesktop settings → Vencord → Themes → $VESKTOP_THEME_FILE"
        fi
    else
        echo "$VESKTOP_SETTINGS not found (Vesktop may not have been launched yet)."
        echo "Launch Vesktop once to generate it, then either re-run this script or enable"
        echo "the theme manually: Vesktop settings → Vencord → Themes → $VESKTOP_THEME_FILE"
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