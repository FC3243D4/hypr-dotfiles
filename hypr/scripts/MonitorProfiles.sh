#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Pre-configured Monitor Profiles

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iconsDir="$HOME/.config/swaync/icons"
scriptsDir="$HOME/.config/hypr/scripts"
monitorDir="$HOME/.config/hypr/Monitor_Profiles"
target="$HOME/.config/hypr/UserConfigs/monitors.lua"
rofiTheme="$HOME/.config/rofi/config-Monitors.rasi"
msg="❗NOTE:❗ This will overwrite $target"

# Files to ignore in the listing
ignoreFiles=("README")

# List of profiles: strip extension, sort numerically then alphabetically
monitorProfilesList=$(find -L "$monitorDir" -maxdepth 1 -type f \( -name "*.lua" -o -name "*.conf" \) \
    | sed 's/.*\///' | sed 's/\.\(lua\|conf\)$//' | sort -V)

for ignored_file in "${ignoreFiles[@]}"; do
    monitorProfilesList=$(echo "$monitorProfilesList" | grep -v -E "^$ignored_file$")
done

# Rofi menu
chosenFile=$(echo "$monitorProfilesList" | rofi -i -dmenu -config "$rofiTheme" -mesg "$msg")

if [[ -n "$chosenFile" ]]; then
    # Prefer .lua, fall back to .conf for legacy profiles
    if [[ -f "$monitorDir/$chosenFile.lua" ]]; then
        fullPath="$monitorDir/$chosenFile.lua"
    else
        fullPath="$monitorDir/$chosenFile.conf"
    fi

    cp "$fullPath" "$target"
    notify-send -u low -i "$iconsDir/ok.svg" "$chosenFile" "Monitor Profile Loaded"
fi

sleep 1
"${scriptsDir}/RefreshNoWaybar.sh" &