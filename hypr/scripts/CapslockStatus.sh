#!/usr/bin/env sh

# 1. Retrieve brightness values directly from the kernel LED class
# We append | head -c 1 to safely handle cases where wildcards match multiple files
capsStatus=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -c 1)

# 2. Interpret state (Default to '0' if file is missing or unreadable)
[ -z "$capsStatus" ] && capsStatus="0"

# 3. Format Output for Waybar (Icon-based display)
if [ "$capsStatus" = "1" ]; then
    capsIcon="󰘲 󱨥"
else
    capsIcon="󰘲 󱨦"
fi

# Echo to stdout for Waybar to capture
echo " ${capsIcon} "