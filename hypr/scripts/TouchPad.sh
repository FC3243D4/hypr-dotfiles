#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling/enabling the touchpad at runtime.
# The device name is read from Laptops.lua (touchpadDevice local variable).
# Use `hyprctl devices` to find your touchpad's exact name.
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

notif="$HOME/.config/swaync/icons/ok.svg"
STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
LAPTOPS_LUA="$HOME/.config/hypr/UserConfigs/Laptops.lua"

# Extract touchpad device name from Laptops.lua
# Matches:  local touchpadDevice = "asue1209:00-04f3:319f-touchpad"
get_touchpad_device() {
    grep -oP 'touchpadDevice\s*=\s*"\K[^"]+' "$LAPTOPS_LUA" 2>/dev/null | head -n1
}

TOUCHPAD_DEVICE="$(get_touchpad_device)"

if [ -z "$TOUCHPAD_DEVICE" ]; then
    notify-send -u critical -i "$notif" "TouchPad" "Could not find touchpadDevice in Laptops.lua"
    exit 1
fi

enable_touchpad() {
    printf "true" > "$STATUS_FILE"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
    hyprctl keyword "device[$TOUCHPAD_DEVICE]:enabled" "true"
}

disable_touchpad() {
    printf "false" > "$STATUS_FILE"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
    hyprctl keyword "device[$TOUCHPAD_DEVICE]:enabled" "false"
}

if [ ! -f "$STATUS_FILE" ]; then
    enable_touchpad
else
    status=$(cat "$STATUS_FILE")
    if [ "$status" = "true" ]; then
        disable_touchpad
    else
        enable_touchpad
    fi
fi