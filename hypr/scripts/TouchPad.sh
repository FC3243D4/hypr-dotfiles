#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling/enabling the touchpad at runtime.
# The device name is read from Laptops.lua (touchpadDevice local variable).
# Use `hyprctl devices` to find your touchpad's exact name.
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

notif="$HOME/.config/swaync/icons/ok.svg"
statusFile="$XDG_RUNTIME_DIR/touchpad.status"
laptopsLua="$HOME/.config/hypr/UserConfigs/Laptops.lua"

# Extract touchpad device name from Laptops.lua
# Matches:  local touchpadDevice = "asue1209:00-04f3:319f-touchpad"
get_touchpad_device() {
    grep -oP 'touchpadDevice\s*=\s*"\K[^"]+' "$laptopsLua" 2>/dev/null | head -n1
}

touchpadDevice="$(get_touchpad_device)"

if [ -z "$touchpadDevice" ]; then
    notify-send -u critical -i "$notif" "TouchPad" "Could not find touchpadDevice in Laptops.lua"
    exit 1
fi

enable_touchpad() {
    printf "true" > "$statusFile"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
    hyprctl keyword "device[$touchpadDevice]:enabled" "true"
}

disable_touchpad() {
    printf "false" > "$statusFile"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
    hyprctl keyword "device[$touchpadDevice]:enabled" "false"
}

if [ ! -f "$statusFile" ]; then
    enable_touchpad
else
    status=$(cat "$statusFile")
    if [ "$status" = "true" ]; then
        disable_touchpad
    else
        enable_touchpad
    fi
fi