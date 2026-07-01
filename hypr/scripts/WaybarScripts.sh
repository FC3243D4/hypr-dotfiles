#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Waybar modules script — reads defaults from 01-UserDefaults.lua

DEFAULTS_LUA="$HOME/.config/hypr/UserConfigs/01-UserDefaults.lua"
READER="$HOME/.config/hypr/scripts/read_lua_defaults.py"

read_default() {
    python3 "$READER" "$1" "$DEFAULTS_LUA" 2>/dev/null || true
}

if [[ ! -f "$DEFAULTS_LUA" ]]; then
    echo "Error: $DEFAULTS_LUA not found!" >&2
    exit 1
fi

term=$(read_default term)
files=$(read_default files)

if [[ -z "$term" ]]; then
    echo "Error: \$term is not set in $DEFAULTS_LUA" >&2
    exit 1
fi

if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    $files &
else
    echo "Usage: $0 [--btop | --nvtop | --nmtui | --term | --files]"
    echo "--btop    : Open btop in a new terminal"
    echo "--nvtop   : Open nvtop in a new terminal"
    echo "--nmtui   : Open nmtui in a new terminal"
    echo "--term    : Launch a terminal window"
    echo "--files   : Launch a file manager"
fi
