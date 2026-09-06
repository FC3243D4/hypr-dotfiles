#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This script is used to play system sounds.
# Script is used by Volume.Sh and ScreenShots.sh 

theme="freedesktop" # Set the theme for the system sounds.
mute=false          # Set to true to mute the system sounds.

# Mute individual sounds here.
muteScreenshots=false
muteVolume=false

# Exit if the system sounds are muted.
if [[ "$mute" = true ]]; then
    exit 0
fi

# Choose the sound to play.
if [[ "$1" == "--screenshot" ]]; then
    if [[ "$muteScreenshots" = true ]]; then
        exit 0
    fi
    soundOption="screen-capture.*"
elif [[ "$1" == "--volume" ]]; then
    if [[ "$muteVolume" = true ]]; then
        exit 0
    fi
    soundOption="audio-volume-change.*"
elif [[ "$1" == "--error" ]]; then
    if [[ "$muteScreenshots" = true ]]; then
        exit 0
    fi
    soundOption="dialog-error.*"
else
    echo -e "Available sounds: --screenshot, --volume, --error"
    exit 0
fi

# Set the directory defaults for system sounds.
if [ -d "/run/current-system/sw/share/sounds" ]; then
    systemDir="/run/current-system/sw/share/sounds" # NixOS
else
    systemDir="/usr/share/sounds"
fi
userDir="$HOME/.local/share/sounds"
defaultTheme="freedesktop"

# Prefer the user's theme, but use the system's if it doesn't exist.
sDIR="$systemDir/$defaultTheme"
if [ -d "$userDir/$theme" ]; then
    sDIR="$userDir/$theme"
elif [ -d "$systemDir/$theme" ]; then
    sDIR="$systemDir/$theme"
fi

# Get the theme that it inherits.
iTheme=$(cat "$sDIR/index.theme" | grep -i "inherits" | cut -d "=" -f 2)
iDIR="$sDIR/../$iTheme"

# Find the sound file and play it.
soundFile=$(find -L $sDIR/stereo -name "$soundOption" -print -quit)
if ! test -f "$soundFile"; then
    soundFile=$(find -L $iDIR/stereo -name "$soundOption" -print -quit)
    if ! test -f "$soundFile"; then
        soundFile=$(find -L $userDir/$defaultTheme/stereo -name "$soundOption" -print -quit)
        if ! test -f "$soundFile"; then
            soundFile=$(find -L $systemDir/$defaultTheme/stereo -name "$soundOption" -print -quit)
            if ! test -f "$soundFile"; then
                echo "Error: Sound file not found."
                exit 1
            fi
        fi
    fi
fi

# pipewire priority, fallback pulseaudio
pw-play "$soundFile" || pa-play "$soundFile"