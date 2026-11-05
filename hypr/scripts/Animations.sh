#!/usr/bin/env bash
# For applying Animations from different users

# Variables
imageDir="$HOME/.config/swaync/images"
scriptsDir="$HOME/.config/hypr/scripts"
animationsDir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
msg='This will copy animations into UserAnimations.lua'
# list of animation files, sorted alphabetically with numbers first
animationList=$(find -L "$animationsDir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.lua$//' | sort -V)

# Display using vicinae dmenu
chosenFile=$(printf '%s\n' "$animationList" | vicinae dmenu)

# Check if a file was selected
if [[ -n "$chosenFile" ]]; then
    fullPath="$animationsDir/$chosenFile.lua"    
    cp "$fullPath" "$UserConfigs/UserAnimations.lua"    
    notify-send -u low -i "$imageDir/ja.png" "$chosenFile" "Hyprland Animation Loaded"
fi