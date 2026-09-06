#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For searching via web browsers — reads Search_Engine from UserDefaults.lua

defaultsLua="$HOME/.config/hypr/UserConfigs/UserDefaults.lua"
reader="$HOME/.config/hypr/scripts/read_lua_defaults.py"

read_default() {
    python3 "$reader" "$1" "$defaultsLua" 2>/dev/null || true
}

if [[ ! -f "$defaultsLua" ]]; then
    echo "Error: $defaultsLua not found!" >&2
    exit 1
fi

SearchEngine=$(read_default Search_Engine)

if [[ -z "$SearchEngine" ]]; then
    echo "Error: Search_Engine is not set in $defaultsLua" >&2
    exit 1
fi

rofiTheme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

echo "" | rofi -dmenu -config "$rofiTheme" -mesg "$msg" | xargs -I{} xdg-open "$SearchEngine"
