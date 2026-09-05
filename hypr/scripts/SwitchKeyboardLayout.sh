#!/usr/bin/env bash
# This is for changing kb_layouts. Set kb_layouts in SystemSettings.lua

layoutFile="$HOME/.cache/kb_layout"
settingsFile="$HOME/.config/hypr/configs/SystemSettings.lua"
notifIcon="$HOME/.config/swaync/icons/ok.svg"

# Refined ignore list with patterns or specific device names
ignorePatterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Extract kb_layout value from Lua config.
# Handles:  kb_layout = "it,us"  or  kb_layout = "it"
get_kb_layout_from_lua() {
    grep -oP 'kb_layout\s*=\s*"\K[^"]+' "$settingsFile" 2>/dev/null | head -n1
}

# Create layout file with default layout if it does not exist
if [ ! -f "$layoutFile" ]; then
    echo "Creating layout file..."
    raw=$(get_kb_layout_from_lua)
    defaultLayout="${raw%%,*}"   # take first layout before any comma
    defaultLayout="${defaultLayout:-us}"
    echo "$defaultLayout" > "$layoutFile"
    echo "Default layout set to $defaultLayout"
fi

currentLayout=$(cat "$layoutFile")
echo "Current layout: $currentLayout"

# Read available layouts from Lua settings file
if [ -f "$settingsFile" ]; then
    raw=$(get_kb_layout_from_lua)
    if [ -z "$raw" ]; then
        echo "Error: could not find kb_layout in $settingsFile" >&2
        exit 1
    fi
    IFS=',' read -r -a layoutMapping <<< "$raw"
else
    echo "Settings file not found: $settingsFile" >&2
    exit 1
fi

layoutCount=${#layoutMapping[@]}
echo "Number of layouts: $layoutCount"

# Find current layout index and calculate next layout
currentIndex=0
for ((i = 0; i < layoutCount; i++)); do
    if [ "$currentLayout" == "${layoutMapping[i]}" ]; then
        currentIndex=$i
        break
    fi
done

nextIndex=$(( (currentIndex + 1) % layoutCount ))
newLayout="${layoutMapping[nextIndex]}"
echo "Next layout: $newLayout"

# Helpers
get_keyboard_names() {
    hyprctl devices -j | jq -r '.keyboards[].name'
}

is_ignored() {
    local deviceName=$1
    for pattern in "${ignorePatterns[@]}"; do
        if [[ "$deviceName" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

change_layout() {
    local errorFound=false
    while read -r name; do
        if is_ignored "$name"; then
            echo "Skipping ignored device: $name"
            continue
        fi
        echo "Switching layout for $name to $newLayout..."
        hyprctl switchxkblayout "$name" "$nextIndex"
        if [ $? -ne 0 ]; then
            echo "Error while switching layout for $name." >&2
            errorFound=true
        fi
    done <<< "$(get_keyboard_names)"
    $errorFound && return 1
    return 0
}

if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
else
    notify-send -u low -i "$notifIcon" " kb_layout: $newLayout"
    echo "Layout change notification sent."
fi

echo "$newLayout" > "$layoutFile"