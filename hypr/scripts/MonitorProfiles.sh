#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Pre-configured Monitor Profiles

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/icons"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
monitor_dir="$HOME/.config/hypr/Monitor_Profiles"
target="$HOME/.config/hypr/UserConfigs/monitors.lua"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg="❗NOTE:❗ This will overwrite $target"

# Files to ignore in the listing
ignore_files=("README")

# List of profiles: strip extension, sort numerically then alphabetically
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f \( -name "*.lua" -o -name "*.conf" \) \
    | sed 's/.*\///' | sed 's/\.\(lua\|conf\)$//' | sort -V)

for ignored_file in "${ignore_files[@]}"; do
    mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

# Rofi menu
chosen_file=$(echo "$mon_profiles_list" | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    # Prefer .lua, fall back to .conf for legacy profiles
    if [[ -f "$monitor_dir/$chosen_file.lua" ]]; then
        full_path="$monitor_dir/$chosen_file.lua"
    else
        full_path="$monitor_dir/$chosen_file.conf"
    fi

    cp "$full_path" "$target"
    notify-send -u low -i "$iDIR/ok.svg" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
"${SCRIPTSDIR}/RefreshNoWaybar.sh" &