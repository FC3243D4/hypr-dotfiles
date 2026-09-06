#!/usr/bin/env sh

# 1. Retrieve brightness values directly from the kernel LED class
# We append | head -c 1 to safely handle cases where wildcards match multiple files
numlockStatus=$(cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -c 1)

# 2. Interpret state (Default to '0' if file is missing or unreadable)
[ -z "$numlockStatus" ] && numlockStatus="0"

# 3. Format Output for Waybar (Icon-based display)
if [ "$numlockStatus" = "1" ]; then
    numlockIcon="N 󱨥"
else
    numlockIcon="N 󱨦"
fi

# Echo to stdout for Waybar to capture
echo " ${numlockIcon} "