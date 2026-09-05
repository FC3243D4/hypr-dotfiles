#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for changing kb_layouts. Set kb_layouts in "$HOME/.config/hypr/UserConfigs/UserSettings.conf"

notifIcon="$HOME/.config/swaync/icons/ok.svg"
scriptsDir="$HOME/.config/hypr/scripts"

# Refined ignore list with patterns or specific device names
ignorePatterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Function to get keyboard names
get_keyboard_names() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Function to check if a device matches any ignore pattern
is_ignored() {
  local deviceName=$1
  for pattern in "${ignorePatterns[@]}"; do
    if [[ "$deviceName" == *"$pattern"* ]]; then
      return 0 # Device matches ignore pattern
    fi
  done
  return 1 # Device does not match any ignore pattern
}

# Function to get current layout info
# Stores values in layoutMapping, variantMapping and layoutIndex
get_currentLayout_info() {
  local foundKb=false

  # Read from the first non-ignored layout
  while read -r name; do
    if ! is_ignored "$name"; then
      foundKb=true
      local layoutMappingStr=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).layout')
      IFS="," read -r -a layoutMapping <<<"$layoutMappingStr"

      local variantMappingStr=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).variant')
      IFS="," read -r -a variantMapping <<<"$variantMappingStr"

      layoutIndex=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).active_layoutIndex')
      break
    fi
  done <<< "$(get_keyboard_names)"

  $foundKb && return 0
  return 1
}

# Function to change keyboard layout
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
  done <<<"$(get_keyboard_names)"

  $errorFound && return 1
  return 0
}


# Stores values in layoutMapping, variantMapping and layoutIndex
if ! get_currentLayout_info; then
  echo "Could not get current layout information." >&2
  echo "There might not be any keyboards available, \
    or some were unnecessarily set as ignored." >&2
  notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
  echo "Exiting $0 $@" >&2
  exit 1
fi

currentLayout=${layoutMapping[$layoutIndex]}
currentVariant=${variantMapping[$layoutIndex]}

if [[ "$1" == "status" ]]; then
  echo "$currentLayout${currentVariant:+($currentVariant)}"
elif [[ "$1" == "switch" ]]; then
  echo "Current layout: $currentLayout($currentVariant)"

  layout_count=${#layoutMapping[@]}
  echo "Number of layouts: $layout_count"

  nextIndex=$(( (layoutIndex + 1) % layout_count ))
  newLayout="${layoutMapping[$nextIndex]}"
  newVariant="${variantMapping[$nextIndex]}"
  echo "Next layout: $newLayout"

  # Execute layout change and notify
  if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
  else
    notify-send -u low -i "$notifIcon" " kb_layout: $newLayout${newVariant:+($newVariant)}"
    echo "Layout change notification sent."
  fi
else
  echo "Usage: $0 {status|switch}"
fi
