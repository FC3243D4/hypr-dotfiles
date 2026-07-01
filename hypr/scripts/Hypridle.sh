#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for custom version of waybar idle_inhibitor which activates / deactivates hypridle instead

PROCESS="hypridle"

if [[ "$1" == "status" ]]; then
    sleep 1
    if pgrep -x "$PROCESS" >/dev/null; then
        echo '{"text": "󰷛 󱨥", "class": "active", "tooltip": "idle_inhibitor NOT ACTIVE\nLeft Click: Activate\nRight Click: Lock Screen"}'
    else
        echo '{"text": "󰷛 󱨦", "class": "notactive", "tooltip": "idle_inhibitor is ACTIVE\nLeft Click: Deactivate\nRight Click: Lock Screen"}'
    fi
elif [[ "$1" == "toggle" ]]; then
    if pgrep -x hypridle >/dev/null; then
        notify-send -u low -t 3000 "Automatic hyprlock is disabled" "Left Click: Enable\nRight Click: Manually Lock Screen"
        pkill hypridle
    else
        hypridle &
        notify-send -u low -t 3000 "Automatic hyprlock is enabled" "Left Click: Disable\nRight Click: Manually Lock Screen"
    fi
else
    echo "Usage: $0 {status|toggle}"
    exit 1
fi
