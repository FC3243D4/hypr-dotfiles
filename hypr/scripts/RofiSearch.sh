#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For searching via web browsers — reads Search_Engine from 01-UserDefaults.lua

DEFAULTS_LUA="$HOME/.config/hypr/UserConfigs/01-UserDefaults.lua"
READER="$HOME/.config/hypr/scripts/read_lua_defaults.py"

read_default() {
    python3 "$READER" "$1" "$DEFAULTS_LUA" 2>/dev/null || true
}

if [[ ! -f "$DEFAULTS_LUA" ]]; then
    echo "Error: $DEFAULTS_LUA not found!" >&2
    exit 1
fi

Search_Engine=$(read_default Search_Engine)

if [[ -z "$Search_Engine" ]]; then
    echo "Error: Search_Engine is not set in $DEFAULTS_LUA" >&2
    exit 1
fi

rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg" | xargs -I{} xdg-open "$Search_Engine"
