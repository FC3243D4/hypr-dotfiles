#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for changing kb_layouts. Set kb_layouts in SystemSettings.lua

layout_file="$HOME/.cache/kb_layout"
settings_file="$HOME/.config/hypr/configs/SystemSettings.lua"
notif_icon="$HOME/.config/swaync/images/ja.png"

# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Extract kb_layout value from Lua config.
# Handles:  kb_layout = "it,us"  or  kb_layout = "it"
get_kb_layout_from_lua() {
    grep -oP 'kb_layout\s*=\s*"\K[^"]+' "$settings_file" 2>/dev/null | head -n1
}

# Create layout file with default layout if it does not exist
if [ ! -f "$layout_file" ]; then
    echo "Creating layout file..."
    raw=$(get_kb_layout_from_lua)
    default_layout="${raw%%,*}"   # take first layout before any comma
    default_layout="${default_layout:-us}"
    echo "$default_layout" > "$layout_file"
    echo "Default layout set to $default_layout"
fi

current_layout=$(cat "$layout_file")
echo "Current layout: $current_layout"

# Read available layouts from Lua settings file
if [ -f "$settings_file" ]; then
    raw=$(get_kb_layout_from_lua)
    if [ -z "$raw" ]; then
        echo "Error: could not find kb_layout in $settings_file" >&2
        exit 1
    fi
    IFS=',' read -r -a layout_mapping <<< "$raw"
else
    echo "Settings file not found: $settings_file" >&2
    exit 1
fi

layout_count=${#layout_mapping[@]}
echo "Number of layouts: $layout_count"

# Find current layout index and calculate next layout
current_index=0
for ((i = 0; i < layout_count; i++)); do
    if [ "$current_layout" == "${layout_mapping[i]}" ]; then
        current_index=$i
        break
    fi
done

next_index=$(( (current_index + 1) % layout_count ))
new_layout="${layout_mapping[next_index]}"
echo "Next layout: $new_layout"

# Helpers
get_keyboard_names() {
    hyprctl devices -j | jq -r '.keyboards[].name'
}

is_ignored() {
    local device_name=$1
    for pattern in "${ignore_patterns[@]}"; do
        if [[ "$device_name" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

change_layout() {
    local error_found=false
    while read -r name; do
        if is_ignored "$name"; then
            echo "Skipping ignored device: $name"
            continue
        fi
        echo "Switching layout for $name to $new_layout..."
        hyprctl switchxkblayout "$name" "$next_index"
        if [ $? -ne 0 ]; then
            echo "Error while switching layout for $name." >&2
            error_found=true
        fi
    done <<< "$(get_keyboard_names)"
    $error_found && return 1
    return 0
}

if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
else
    notify-send -u low -i "$notif_icon" " kb_layout: $new_layout"
    echo "Layout change notification sent."
fi

echo "$new_layout" > "$layout_file"