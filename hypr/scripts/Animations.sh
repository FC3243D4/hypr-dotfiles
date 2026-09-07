#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Animations from different users

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
imageDir="$HOME/.config/swaync/images"
scriptsDir="$HOME/.config/hypr/scripts"
animationsDir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofiTheme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ This will copy animations into UserAnimations.lua'
# list of animation files, sorted alphabetically with numbers first
animationList=$(find -L "$animationsDir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.lua$//' | sort -V)

# Scale window width / column count to the focused monitor's aspect ratio
source "$scriptsDir/RofiWidthScale.sh"
IFS=' ' read -r rofiWidth rofiColumns <<< "$(rofi_scaled_width_and_columns)"

# Don't ask for more columns than the item count can actually fill
itemCount=$(printf '%s\n' "$animationList" | wc -l)
rofiColumns=$(rofi_cap_columns "$rofiColumns" "$itemCount" 7)

# Rofi Menu
chosenFile=$(echo "$animationList" | rofi -i -dmenu -config $rofiTheme -mesg "$msg" \
    -theme-str "window { width: ${rofiWidth}%; } listview { columns: ${rofiColumns}; }")

# Check if a file was selected
if [[ -n "$chosenFile" ]]; then
    fullPath="$animationsDir/$chosenFile.lua"    
    cp "$fullPath" "$UserConfigs/UserAnimations.lua"    
    notify-send -u low -i "$imageDir/ja.png" "$chosenFile" "Hyprland Animation Loaded"
fi