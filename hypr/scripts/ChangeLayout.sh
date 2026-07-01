#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
    hyprctl keyword general:layout dwindle
    # SUPER+O togglesplit only makes sense in dwindle; add it at runtime via Lua eval
    # SUPER+J/K are global and managed by KeybindsLayoutInit.sh
    hyprctl keyword bind "SUPER, O, togglesplit"
    notify-send -e -u low -i "$notif" " Dwindle Layout"
    ;;
"dwindle")
    hyprctl keyword general:layout master
    # Drop the dwindle-only togglesplit binding
    hyprctl keyword unbind "SUPER, O"
    notify-send -e -u low -i "$notif" " Master Layout"
    ;;
*) ;;
esac