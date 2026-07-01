#!/usr/bin/env sh

# 1. Retrieve brightness values directly from the kernel LED class
# We append | head -c 1 to safely handle cases where wildcards match multiple files
caps_val=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -c 1)

# 2. Interpret state (Default to '0' if file is missing or unreadable)
[ -z "$caps_val" ] && caps_val="0"

# 3. Format Output for Waybar (Icon-based display)
if [ "$caps_val" = "1" ]; then
    caps_icon="󰘲 󱨥"
else
    caps_icon="󰘲 󱨦"
fi

# Echo to stdout for Waybar to capture
echo " ${caps_icon} "