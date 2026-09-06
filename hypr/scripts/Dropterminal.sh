#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
#
# Made and brought to by Kiran George
# /* -- ✨ https://github.com/SherLock707 ✨ -- */  ##
# Dropdown Terminal
# Usage: ./Dropdown.sh [-d] <terminal_command>
# Example: ./Dropdown.sh foot
#          ./Dropdown.sh -d foot (with debug output)
#          ./Dropdown.sh "kitty -e zsh"
#          ./Dropdown.sh "alacritty --working-directory /home/user"

debug=false
specialWorkspaces="special:scratchpad"
addressFile="/tmp/dropdown_terminal_addr"

# Dropdown size and position configuration (percentages)
widthPercent=65  # Width as percentage of screen width
heightPercent=65 # Height as percentage of screen height
yPercent=10      # Y position as percentage from top (X is auto-centered)

# Animation settings
animationDuration=100 # milliseconds
slideStep=5
slideDelay=5 # milliseconds between steps

# Parse arguments
if [ "$1" = "-d" ]; then
  debug=true
  shift
fi

terminalCmd="$1"

# Debug echo function
debug_echo() {
  if [ "$debug" = true ]; then
    echo "$@"
  fi
}

# Validate input
if [ -z "$terminalCmd" ]; then
  echo "Missing terminal command. Usage: $0 [-d] <terminal_command>"
  echo "Examples:"
  echo "  $0 foot"
  echo "  $0 -d foot (with debug output)"
  echo "  $0 'kitty -e zsh'"
  echo "  $0 'alacritty --working-directory /home/user'"
  echo ""
  echo "Edit the script to modify size and position:"
  echo "  widthPercent  - Width as percentage of screen (default: 50)"
  echo "  heightPercent - Height as percentage of screen (default: 50)"
  echo "  yPercent      - Y position from top as percentage (default: 5)"
  echo "  Note: X position is automatically centered"
  exit 1
fi

# Function to get window geometry
get_window_geometry() {
  local addr="$1"
  hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"'
}

# Function to animate window slide down (show)
animate_slide_down() {
  local addr="$1"
  local targetX="$2"
  local targetY="$3"
  local width="$4"
  local height="$5"

  debug_echo "Animating slide down for window $addr to position $targetX,$targetY"

  # Start position (above screen)
  local startY=$((targetY - height - 50))

  # Calculate step size
  local stepY=$(((targetY - startY) / slideStep))

  # Move window to start position instantly (off-screen)
  hyprctl dispatch movewindowpixel "exact $targetX $startY,address:$addr" >/dev/null 2>&1
  sleep 0.05

  # Animate slide down
  for i in $(seq 1 $slideStep); do
    local currentY=$((startY + (stepY * i)))
    hyprctl dispatch movewindowpixel "exact $targetX $currentY,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done

  # Ensure final position is exact
  hyprctl dispatch movewindowpixel "exact $targetX $targetY,address:$addr" >/dev/null 2>&1
}

# Function to animate window slide up (hide)
animate_slide_up() {
  local addr="$1"
  local startX="$2"
  local startY="$3"
  local width="$4"
  local height="$5"

  debug_echo "Animating slide up for window $addr from position $startX,$startY"

  # End position (above screen)
  local endY=$((startY - height - 50))

  # Calculate step size
  local stepY=$(((startY - endY) / slideStep))

  # Animate slide up
  for i in $(seq 1 $slideStep); do
    local currentY=$((startY - (stepY * i)))
    hyprctl dispatch movewindowpixel "exact $startX $currentY,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done

  debug_echo "Slide up animation completed"
}

# Function to get monitor info including scale and name of focused monitor
get_monitor_info() {
  local monitorData=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height) \(.scale) \(.name)"')
  if [ -z "$monitorData" ] || [[ "$monitorData" =~ ^null ]]; then
    debug_echo "Error: Could not get focused monitor information"
    return 1
  fi
  echo "$monitorData"
}

# Function to calculate dropdown position with proper scaling and centering
calculate_dropdown_position() {
  local monitorInfo=$(get_monitor_info)

  if [ $? -ne 0 ] || [ -z "$monitorInfo" ]; then
    debug_echo "Error: Failed to get monitor info, using fallback values"
    echo "100 100 800 600 fallback-monitor"
    return 1
  fi

  local monX=$(echo $monitorInfo | cut -d' ' -f1)
  local monY=$(echo $monitorInfo | cut -d' ' -f2)
  local monWidth=$(echo $monitorInfo | cut -d' ' -f3)
  local monHeight=$(echo $monitorInfo | cut -d' ' -f4)
  local monScale=$(echo $monitorInfo | cut -d' ' -f5)
  local monName=$(echo $monitorInfo | cut -d' ' -f6)

  debug_echo "Monitor info: x=$monX, y=$monY, width=$monWidth, height=$monHeight, scale=$monScale"

  # Validate scale value and provide fallback
  if [ -z "$monScale" ] || [ "$monScale" = "null" ] || [ "$monScale" = "0" ]; then
    debug_echo "Invalid scale value, using 1.0 as fallback"
    monScale="1.0"
  fi

  # Calculate logical dimensions by dividing physical dimensions by scale
  local logicalWidth logicalHeight
  if command -v bc >/dev/null 2>&1; then
    # Use bc for precise floating point calculation
    logicalWidth=$(echo "scale=0; $monWidth / $monScale" | bc | cut -d'.' -f1)
    logicalHeight=$(echo "scale=0; $monHeight / $monScale" | bc | cut -d'.' -f1)
  else
    # Fallback to integer math (multiply by 100 for precision, then divide)
    local scaleInt=$(echo "$monScale" | sed 's/\.//' | sed 's/^0*//')
    if [ -z "$scaleInt" ]; then scaleInt=100; fi

    logicalWidth=$(((monWidth * 100) / scaleInt))
    logicalHeight=$(((monHeight * 100) / scaleInt))
  fi

  # Ensure we have valid integer values
  if ! [[ "$logicalWidth" =~ ^-?[0-9]+$ ]]; then logicalWidth=$monWidth; fi
  if ! [[ "$logicalHeight" =~ ^-?[0-9]+$ ]]; then logicalHeight=$monHeight; fi

  debug_echo "Physical resolution: ${monWidth}x${monHeight}"
  debug_echo "Logical resolution: ${logicalWidth}x${logicalHeight} (physical ÷ scale)"

  # Calculate window dimensions based on LOGICAL space percentages
  local width=$((logicalWidth * widthPercent / 100))
  local height=$((logicalHeight * heightPercent / 100))

  # Calculate Y position from top based on percentage of LOGICAL height
  local yOffset=$((logicalHeight * yPercent / 100))

  # Calculate centered X position in LOGICAL space
  local xOffset=$(((logicalWidth - width) / 2))

  # Apply monitor offset to get final positions in logical coordinates
  local finalX=$((monX + xOffset))
  local finalY=$((monY + yOffset))

  debug_echo "Window size: ${width}x${height} (logical pixels)"
  debug_echo "Final position: x=$finalX, y=$finalY (logical coordinates)"
  debug_echo "Hyprland will scale these to physical coordinates automatically"

  echo "$finalX $finalY $width $height $monName"
}

# Get the current workspace
currentWorkspace=$(hyprctl activeworkspace -j | jq -r '.id')

# Function to get stored terminal address
get_terminal_address() {
  if [ -f "$addressFile" ] && [ -s "$addressFile" ]; then
    cut -d' ' -f1 "$addressFile"
  fi
}

# Function to get stored monitor name
get_terminal_monitor() {
  if [ -f "$addressFile" ] && [ -s "$addressFile" ]; then
    cut -d' ' -f2- "$addressFile"
  fi
}

# Function to check if terminal exists
terminal_exists() {
  local addr=$(get_terminal_address)
  if [ -n "$addr" ]; then
    hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1
  else
    return 1
  fi
}

# Function to check if terminal is in special workspace
terminal_in_special() {
  local addr=$(get_terminal_address)
  if [ -n "$addr" ]; then
    hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "special:scratchpad")' >/dev/null 2>&1
  else
    return 1
  fi
}

# Function to spawn terminal and capture its address
spawn_terminal() {
  debug_echo "Creating new dropdown terminal with command: $terminalCmd"

  # Calculate dropdown position for later use
  local posInfo=$(calculate_dropdown_position)
  if [ $? -ne 0 ]; then
    debug_echo "Warning: Using fallback positioning"
  fi

  local targetX=$(echo $posInfo | cut -d' ' -f1)
  local targetY=$(echo $posInfo | cut -d' ' -f2)
  local width=$(echo $posInfo | cut -d' ' -f3)
  local height=$(echo $posInfo | cut -d' ' -f4)
  local monitorName=$(echo $posInfo | cut -d' ' -f5)

  debug_echo "Target position: ${targetX},${targetY}, size: ${width}x${height}"

  # Get window count before spawning
  local windowsBefore=$(hyprctl clients -j)
  local countBefore=$(echo "$windowsBefore" | jq 'length')

  # Launch terminal directly in special workspace to avoid visible spawn
  hyprctl dispatch exec "[float; size $width $height; workspace special:scratchpad silent] $terminalCmd"

  # Wait for window to appear
  sleep 0.1

  # Get windows after spawning
  local windowsAfter=$(hyprctl clients -j)
  local countAfter=$(echo "$windowsAfter" | jq 'length')

  local newAddress=""

  if [ "$countAfter" -gt "$countBefore" ]; then
    # Find the new window by comparing before/after lists
    newAddress=$(comm -13 \
      <(echo "$windowsBefore" | jq -r '.[].address' | sort) \
      <(echo "$windowsAfter" | jq -r '.[].address' | sort) |
      head -1)
  fi

  # Fallback: try to find by the most recently mapped window
  if [ -z "$newAddress" ] || [ "$newAddress" = "null" ]; then
    newAddress=$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[-1] | .address')
  fi

  if [ -n "$newAddress" ] && [ "$newAddress" != "null" ]; then
    # Store the address and monitor name
    echo "$newAddress $monitorName" >"$addressFile"
    debug_echo "Terminal created with address: $newAddress in special workspace on monitor $monitorName"

    # Small delay to ensure it's properly in special workspace
    sleep 0.2

    # Now bring it back with the same animation as subsequent shows
    # Use movetoworkspacesilent to avoid affecting workspace history
    hyprctl dispatch movetoworkspacesilent "$currentWorkspace,address:$newAddress"
    hyprctl dispatch pin "address:$newAddress"
    animate_slide_down "$newAddress" "$targetX" "$targetY" "$width" "$height"

    return 0
  fi

  debug_echo "Failed to get terminal address"
  return 1
}

# Main logic
if terminal_exists; then
  terminalAddress=$(get_terminal_address)
  debug_echo "Found existing terminal: $terminalAddress"
  focusedMonitor=$(get_monitor_info | awk '{print $6}')
  dropdownMonitor=$(get_terminal_monitor)
  if [ "$focusedMonitor" != "$dropdownMonitor" ]; then
    debug_echo "Monitor focus changed: moving dropdown to $focusedMonitor"
    # Calculate new position for focused monitor
    posInfo=$(calculate_dropdown_position)
    targetX=$(echo $posInfo | cut -d' ' -f1)
    targetY=$(echo $posInfo | cut -d' ' -f2)
    width=$(echo $posInfo | cut -d' ' -f3)
    height=$(echo $posInfo | cut -d' ' -f4)
    monitorName=$(echo $posInfo | cut -d' ' -f5)
    # Move and resize window
    hyprctl dispatch movewindowpixel "exact $targetX $targetY,address:$terminalAddress"
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$terminalAddress"
    # Update addressFile
    echo "$terminalAddress $monitorName" >"$addressFile"
  fi

  if terminal_in_special; then
    debug_echo "Bringing terminal from scratchpad with slide down animation"

    # Calculate target position
    posInfo=$(calculate_dropdown_position)
    targetX=$(echo $posInfo | cut -d' ' -f1)
    targetY=$(echo $posInfo | cut -d' ' -f2)
    width=$(echo $posInfo | cut -d' ' -f3)
    height=$(echo $posInfo | cut -d' ' -f4)

    # Use movetoworkspacesilent to avoid affecting workspace history
    hyprctl dispatch movetoworkspacesilent "$currentWorkspace,address:$terminalAddress"
    hyprctl dispatch pin "address:$terminalAddress"

    # Set size and animate slide down
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$terminalAddress"
    animate_slide_down "$terminalAddress" "$targetX" "$targetY" "$width" "$height"

    hyprctl dispatch focuswindow "address:$terminalAddress"
  else
    debug_echo "Hiding terminal to scratchpad with slide up animation"

    # Get current geometry for animation
    geometry=$(get_window_geometry "$terminalAddress")
    if [ -n "$geometry" ]; then
      currX=$(echo $geometry | cut -d' ' -f1)
      currY=$(echo $geometry | cut -d' ' -f2)
      currWidth=$(echo $geometry | cut -d' ' -f3)
      currHeight=$(echo $geometry | cut -d' ' -f4)

      debug_echo "Current geometry: ${currX},${currY} ${currWidth}x${currHeight}"

      # Animate slide up first
      animate_slide_up "$terminalAddress" "$currX" "$currY" "$currWidth" "$currHeight"

      # Small delay then move to special workspace and unpin
      sleep 0.1
      hyprctl dispatch pin "address:$terminalAddress" # Unpin (toggle)
      hyprctl dispatch movetoworkspacesilent "$specialWorkspaces,address:$terminalAddress"
    else
      debug_echo "Could not get window geometry, moving to scratchpad without animation"
      hyprctl dispatch pin "address:$terminalAddress"
      hyprctl dispatch movetoworkspacesilent "$specialWorkspaces,address:$terminalAddress"
    fi
  fi
else
  debug_echo "No existing terminal found, creating new one"
  if spawn_terminal; then
    terminalAddress=$(get_terminal_address)
    if [ -n "$terminalAddress" ]; then
      hyprctl dispatch focuswindow "address:$terminalAddress"
    fi
  fi
fi
