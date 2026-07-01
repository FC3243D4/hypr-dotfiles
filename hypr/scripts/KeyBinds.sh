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
HYPR_DIR="$HOME/.config/hypr"
SCRIPTS_DIR="$HYPR_DIR/scripts"
PARSER="$SCRIPTS_DIR/keybinds_parser.py"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# Config files to parse (order matters: last file = user overrides)
keybinds_lua="$HYPR_DIR/configs/Keybinds.lua"
user_keybinds_lua="$HYPR_DIR/UserConfigs/UserKeybinds.lua"
laptop_lua="$HYPR_DIR/UserConfigs/Laptops.lua"

files=("$keybinds_lua" "$user_keybinds_lua")
[[ -f "$laptop_lua" ]] && files+=("$laptop_lua")

# Verify parser exists
if [[ ! -f "$PARSER" ]]; then
    notify-send -u critical "KeyBinds.sh" "keybinds_parser.py not found at $PARSER"
    exit 1
fi

# Run parser — stdout = formatted keybind lines for rofi
display_keybinds=$(python3 "$PARSER" "${files[@]}")

if [[ -z "$display_keybinds" || "$display_keybinds" == "no keybinds found." ]]; then
    notify-send -u normal "KeyBinds" "No keybinds found. Check your Lua config files."
    exit 1
fi

# Append missing-unbind suggestions count to rofi message if any were found
suggestions_path_file="/tmp/hypr_keybind_suggestions_file"
if [[ -f "$suggestions_path_file" ]]; then
    suggestions_file="$(cat "$suggestions_path_file")"
    if [[ -f "$suggestions_file" ]]; then
        count=$(grep -c 'hl.unbind' "$suggestions_file" 2>/dev/null || echo 0)
        if (( count > 0 )); then
            msg="$msg | ⚠ $count override(s) missing hl.unbind() — see $suggestions_file"
        fi
    fi
fi

# Display in rofi
printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"