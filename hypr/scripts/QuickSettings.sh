#!/usr/bin/env bash
# Vicinae menu for KooL Hyprland Quick Settings (SUPER SHIFT E)

defaultsLua="$HOME/.config/hypr/UserConfigs/UserDefaults.lua"
reader="$HOME/.config/hypr/scripts/read_lua_defaults.py"

read_default() {
    python3 "$reader" "$1" "$defaultsLua" 2>/dev/null || true
}

if [[ ! -f "$defaultsLua" ]]; then
    notify-send -u critical "Quick Settings" "$defaultsLua not found"
    exit 1
fi

term=$(read_default term)
edit=$(read_default EDITOR)

if [[ -z "$term" || -z "$edit" ]]; then
    notify-send -u critical "Quick Settings" "Could not read term/EDITOR from $defaultsLua"
    exit 1
fi

# Variables
configs="$HOME/.config/hypr/configs"
userConfigs="$HOME/.config/hypr/UserConfigs"
iconsDirectory="$HOME/.config/swaync/icons"
scriptsDir="$HOME/.config/hypr/scripts"
wallpaperChangerDir="$HOME/.config/WallpaperChanger"

# ── Submenus ──────────────────────────────────────────────────────────

main_menu() {
    cat <<MENU
USER CUSTOMIZATIONS
SYSTEM DEFAULTS
UTILITIES
MENU
}

user_customizations_menu() {
    cat <<MENU
Edit User Defaults
Edit User ENV variables
Edit User Keybinds
Edit User Startup Apps (overlay)
Edit User Window Rules (overlay)
Edit User Settings
Edit User Decorations
Edit User Animations
Edit User Laptop Settings
MENU
}

system_defaults_menu() {
    cat <<MENU
Edit System Default Keybinds
Edit System Default Startup Apps
Edit System Default Window Rules
Edit System Default Settings
Edit Game Mode Services/Containers
MENU
}

utilities_menu() {
    cat <<MENU
Configure WallpaperChanger icons override
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
Choose Hyprland Animations
Search for Keybinds
Toggle Game Mode
MENU
}

# ── Main Logic ────────────────────────────────────────────────────────

main() {
    # Step 1: Pick top-level category via vicinae dmenu
    category=$(main_menu | vicinae dmenu)
    [[ -z "$category" ]] && exit 0

    # Step 2: Open corresponding submenu
    case "$category" in
        "--- USER CUSTOMIZATIONS ---")
            choice=$(user_customizations_menu | vicinae dmenu)
            ;;
        "--- SYSTEM DEFAULTS  ---")
            choice=$(system_defaults_menu | vicinae dmenu)
            ;;
        "--- UTILITIES ---")
            choice=$(utilities_menu | vicinae dmenu)
            ;;
        *)
            exit 0
            ;;
    esac

    [[ -z "$choice" ]] && exit 0

    # Step 3: Handle target option selection & execution
    case "$choice" in
        # ── User config files ─────────────────────────────────────────────────
        "Edit User Defaults")                   file="$userConfigs/UserDefaults.lua" ;;
        "Edit User ENV variables")              file="$userConfigs/ENVariables.lua" ;;
        "Edit User Keybinds")                   file="$userConfigs/UserKeybinds.lua" ;;
        "Edit User Startup Apps (overlay)")     file="$userConfigs/Startup_Apps.lua" ;;
        "Edit User Window Rules (overlay)")     file="$userConfigs/WindowRules.lua" ;;
        "Edit User Settings")                   file="$userConfigs/UserSettings.lua" ;;
        "Edit User Decorations")                file="$userConfigs/UserDecorations.lua" ;;
        "Edit User Animations")                 file="$userConfigs/UserAnimations.lua" ;;
        "Edit User Laptop Settings")            file="$userConfigs/Laptops.lua" ;;

        # ── System default config files ───────────────────────────────────────
        "Edit System Default Keybinds")         file="$configs/Keybinds.lua" ;;
        "Edit System Default Startup Apps")     file="$configs/Startup_Apps.lua" ;;
        "Edit System Default Window Rules")     file="$configs/WindowRules.lua" ;;
        "Edit System Default Settings")         file="$configs/SystemSettings.lua" ;;
        "Edit Game Mode Services/Containers")   file="$scriptsDir/GameModeProcesses" ;;

        # ── Tool launchers ────────────────────────────────────────────────────
        "Configure WallpaperChanger icons override") file="$wallpaperChangerDir/themeRefresherSupportScripts/icon-overrides.conf" ;;
        "Choose Kitty Terminal Theme")
            "$scriptsDir/KittyThemes.sh"; return ;;
        "Configure Monitors (nwg-displays)"|"Configure Workspace Rules (nwg-displays)")
            command -v nwg-displays &>/dev/null || { notify-send -i "$iconsDirectory/error.svg" "E-R-R-O-R" "Install nwg-displays first"; exit 1; }
            nwg-displays; return ;;
        "Choose Hyprland Animations")           "$scriptsDir/Animations.sh";       return ;;
        "Search for Keybinds")                  "$scriptsDir/KeyBinds.sh";          return ;;
        "Toggle Game Mode")                     "$scriptsDir/GameMode.sh";          return ;;
        *) return ;;
    esac

    if [[ -n "$file" ]]; then
        $term -e $edit "$file"
    fi
}

main
