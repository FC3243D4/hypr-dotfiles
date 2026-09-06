#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Searchable keybinds using rofi — delegates all parsing to keybinds_parser.py
# which understands the Lua hl.bind() syntax.

# Kill anything that would interfere
pkill yad || true
if pidof rofi > /dev/null; then
    pkill rofi
fi

# Paths
hyprDirectory="$HOME/.config/hypr"
scriptsDirectory="$hyprDirectory/scripts"
parser="$scriptsDirectory/keybinds_parser.py"
rofiTheme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# Config files to parse (order matters: last file = user overrides)
keybindsLua="$hyprDirectory/configs/Keybinds.lua"
userKeybindsLua="$hyprDirectory/UserConfigs/UserKeybinds.lua"
laptopLua="$hyprDirectory/UserConfigs/Laptops.lua"

files=("$keybindsLua" "$userKeybindsLua")
[[ -f "$laptopLua" ]] && files+=("$laptopLua")

# Verify parser exists
if [[ ! -f "$parser" ]]; then
    notify-send -u critical "KeyBinds.sh" "keybinds_parser.py not found at $parser"
    exit 1
fi

# Run parser — stdout = formatted keybind lines for rofi
displayKeybinds=$(python3 "$parser" "${files[@]}")

if [[ -z "$displayKeybinds" || "$displayKeybinds" == "no keybinds found." ]]; then
    notify-send -u normal "KeyBinds" "No keybinds found. Check your Lua config files."
    exit 1
fi

# Append missing-unbind suggestions count to rofi message if any were found
suggestionsPathFile="/tmp/hypr_keybind_suggestions_file"
if [[ -f "$suggestionsPathFile" ]]; then
    suggestionsFile="$(cat "$suggestionsPathFile")"
    if [[ -f "$suggestionsFile" ]]; then
        count=$(grep -c 'hl.unbind' "$suggestionsFile" 2>/dev/null || echo 0)
        if (( count > 0 )); then
            msg="$msg | ⚠ $count override(s) missing hl.unbind() — see $suggestionsFile"
        fi
    fi
fi

# Display in rofi
printf '%s\n' "$displayKeybinds" | rofi -dmenu -i -config "$rofiTheme" -mesg "$msg"