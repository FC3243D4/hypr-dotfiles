#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Rofi menu for KooL Hyprland Quick Settings (SUPER SHIFT E)

DEFAULTS_LUA="$HOME/.config/hypr/UserConfigs/01-UserDefaults.lua"
READER="$HOME/.config/hypr/scripts/read_lua_defaults.py"

read_default() {
    python3 "$READER" "$1" "$DEFAULTS_LUA" 2>/dev/null || true
}

if [[ ! -f "$DEFAULTS_LUA" ]]; then
    notify-send -u critical "Quick Settings" "$DEFAULTS_LUA not found"
    exit 1
fi

term=$(read_default term)
edit=$(read_default EDITOR)

if [[ -z "$term" || -z "$edit" ]]; then
    notify-send -u critical "Quick Settings" "Could not read term/EDITOR from $DEFAULTS_LUA"
    exit 1
fi

# Variables
configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="$HOME/.config/swaync/icons"
scriptsDir="$HOME/.config/hypr/scripts"

menu() {
    cat <<MENU
--- USER CUSTOMIZATIONS ---
Edit User Defaults
Edit User Keybinds
Edit User ENV variables
Edit User Startup Apps (overlay)
Edit User Window Rules (overlay)
Edit User Settings
Edit User Decorations
Edit User Animations
Edit User Laptop Settings
--- SYSTEM DEFAULTS  ---
Edit System Default Keybinds
Edit System Default Startup Apps
Edit System Default Window Rules
Edit System Default Settings
--- UTILITIES ---
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
MENU
}

main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")

    case "$choice" in
        # ── User config files ─────────────────────────────────────────────────
        "Edit User Defaults")                  file="$UserConfigs/01-UserDefaults.lua" ;;
        "Edit User ENV variables")             file="$UserConfigs/ENVariables.lua" ;;
        "Edit User Keybinds")                  file="$UserConfigs/UserKeybinds.lua" ;;
        "Edit User Startup Apps (overlay)")    file="$UserConfigs/Startup_Apps.lua" ;;
        "Edit User Window Rules (overlay)")    file="$UserConfigs/WindowRules.lua" ;;
        "Edit User Settings")                  file="$UserConfigs/UserSettings.lua" ;;
        "Edit User Decorations")               file="$UserConfigs/UserDecorations.lua" ;;
        "Edit User Animations")                file="$UserConfigs/UserAnimations.lua" ;;
        "Edit User Laptop Settings")           file="$UserConfigs/Laptops.lua" ;;

        # ── System default config files ───────────────────────────────────────
        "Edit System Default Keybinds")        file="$configs/Keybinds.lua" ;;
        "Edit System Default Startup Apps")    file="$configs/Startup_Apps.lua" ;;
        "Edit System Default Window Rules")    file="$configs/WindowRules.lua" ;;
        "Edit System Default Settings")        file="$configs/SystemSettings.lua" ;;

        # ── Tool launchers ────────────────────────────────────────────────────
        "Choose Kitty Terminal Theme")
            "$scriptsDir/Kitty_themes.sh"; return ;;
        "Configure Monitors (nwg-displays)"|"Configure Workspace Rules (nwg-displays)")
            command -v nwg-displays &>/dev/null || { notify-send -i "$iDIR/error.svg" "E-R-R-O-R" "Install nwg-displays first"; exit 1; }
            nwg-displays; return ;;
        "Choose Hyprland Animations") "$scriptsDir/Animations.sh";       return ;;
        "Choose Monitor Profiles")    "$scriptsDir/MonitorProfiles.sh";   return ;;
        "Choose Rofi Themes")         "$scriptsDir/RofiThemeSelector.sh"; return ;;
        "Search for Keybinds")        "$scriptsDir/KeyBinds.sh";          return ;;
        "Toggle Game Mode")           "$scriptsDir/GameMode.sh";          return ;;
        *) return ;;
    esac

    if [[ -n "$file" ]]; then
        $term -e $edit "$file"
    fi
}

if pidof rofi > /dev/null; then
    pkill rofi
fi

main
