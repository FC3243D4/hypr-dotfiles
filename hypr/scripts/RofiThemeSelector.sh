#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Rofi Themes - Script to preview and apply themes by live-reloading the config.

# --- Configuration ---
rofiThemesDirConfig="$HOME/.config/rofi/themes"
rofiThemesConfigLocal="$HOME/.local/share/rofi/themes"
rofiConfigFile="$HOME/.config/rofi/config.rasi"
rofiThemeForThisScript="$HOME/.config/rofi/config-rofi-theme.rasi" # A separate rofi theme for the picker itself
iconsDir="$HOME/.config/swaync/icons"                                      # For notifications

# --- Helper Functions ---

# Function to send a notification
notify_user() {
  notify-send -u low -i "$1" "$2" "$3"
}

# Function to apply the selected rofi theme to the main config file
apply_rofi_theme_to_config() {
  local themeNameToApply="$1"

  # Find the full path of the theme file
  local themePath
  if [[ -f "$rofiThemesDirConfig/$themeNameToApply" ]]; then
    themePath="$rofiThemesDirConfig/$themeNameToApply"
  elif [[ -f "$rofiThemesConfigLocal/$themeNameToApply" ]]; then
    themePath="$rofiThemesConfigLocal/$themeNameToApply"
  else
    notify_user "$iconsDir/error.svg" "Error" "Theme file not found: $themeNameToApply"
    return 1
  fi

  # Use ~ for the home directory in the config path
  local themePathWithTilde="~${themePath#$HOME}"

  # Create a temporary file to safely edit the config
  local tempRofiConfigFile
  tempRofiConfigFile=$(mktemp)
  cp "$rofiConfigFile" "$tempRofiConfigFile"

  # Comment out any existing @theme entry
  sed -i -E 's/^(\s*@theme)/\\/\\/\1/' "$tempRofiConfigFile"

  # Add the new @theme entry at the end of the file
  echo "@theme \"$themePathWithTilde\"" >>"$tempRofiConfigFile"

  # Overwrite the original config file
  cp "$tempRofiConfigFile" "$rofiConfigFile"
  rm "$tempRofiConfigFile"

  # Prune old commented-out theme lines to prevent clutter
  local maxLines=10
  local totalLines=$(grep -c '^//\s*@theme' "$rofiConfigFile")
  if [ "$totalLines" -gt "$maxLines" ]; then
    local excess=$((totalLines - maxLines))
    for ((i = 1; i <= excess; i++)); do
      sed -i '0,/^\s*\/\/@theme/s///' "$rofiConfigFile"
    done
  fi

  return 0
}

# --- Main Script Execution ---

# Check for required directories and files
if [ ! -d "$rofiThemesDirConfig" ] && [ ! -d "$rofiThemesConfigLocal" ]; then
  notify_user "$iconsDir/error.svg" "E-R-R-O-R" "No Rofi themes directory found."
  exit 1
fi

if [ ! -f "$rofiConfigFile" ]; then
  notify_user "$iconsDir/error.svg" "E-R-R-O-R" "Rofi config file not found: $rofiConfigFile"
  exit 1
fi

# Backup the original config content
originalRofiFileContentBackup=$(cat "$rofiConfigFile")

# Generate a sorted list of available theme file names
mapfile -t availableThemesName < <((
  find "$rofiThemesDirConfig" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n" 2>/dev/null
  find "$rofiThemesConfigLocal" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n" 2>/dev/null
) | sort -V -u)

if [ ${#availableThemesName[@]} -eq 0 ]; then
  notify_user "$iconsDir/error.svg" "No Rofi Themes" "No .rasi files found in theme directories."
  exit 1
fi

# Find the currently active theme to set as the initial selection
currentSelectionIndex=0
currentActiveThemePath=$(grep -oP '^\s*@theme\s*"\K[^"]+' "$rofiConfigFile" | tail -n 1)
if [ -n "$currentActiveThemePath" ]; then
  currentActiveThemeName=$(basename "$currentActiveThemePath")
  for i in "${!availableThemesName[@]}"; do
    if [[ "${availableThemesName[$i]}" == "$currentActiveThemeName" ]]; then
      currentSelectionIndex=$i
      break
    fi
  done
fi

# Main preview loop
while true; do
  themeToPreviewNow="${availableThemesName[$currentSelectionIndex]}"

  # Apply the theme for preview
  if ! apply_rofi_theme_to_config "$themeToPreviewNow"; then
    echo "$originalRofiFileContentBackup" >"$rofiConfigFile"
    notify_user "$iconsDir/error.svg" "Preview Error" "Failed to apply $themeToPreviewNow. Reverted."
    exit 1
  fi

  # Prepare theme list for Rofi
  rofiInputList=""
  for themeNameInList in "${availableThemesName[@]}"; do
    rofiInputList+="$(basename "$themeNameInList" .rasi)\n"
  done
  rofiInputListTrimmed="${rofiInputList%\\n}"

  # Launch Rofi and get user's choice
  chosenIndexFromRofi=$(echo -e "$rofiInputListTrimmed" |
    rofi -dmenu -i \
      -format 'i' \
      -p "Rofi Theme" \
      -mesg "‼️ **note** ‼️ Enter: Preview || Ctrl+S: Apply &amp; Exit || Esc: Cancel" \
      -config "$RofiThemeForThisScript" \
      -selected-row "$currentSelectionIndex" \
      -kb-custom-1 "Control+s")

  rofiExitCode=$?

  # Handle Rofi's exit code
  if [ $rofiExitCode -eq 0 ]; then # Enter
    if [[ "$chosenIndexFromRofi" =~ ^[0-9]+$ ]] && [ "$chosenIndexFromRofi" -lt "${#availableThemesName[@]}" ]; then
      currentSelectionIndex="$chosenIndexFromRofi"
    fi
  elif [ $rofiExitCode -eq 1 ]; then # Escape
    notify_user "$iconsDir/note.svg" "Rofi Theme" "Selection cancelled. Reverting to original theme."
    echo "$originalRofiFileContentBackup" >"$rofiConfigFile"
    break
  elif [ $rofiExitCode -eq 10 ]; then # Custom bind 1 (Ctrl+S)
    notify_user "$iconsDir/ok.svg" "Rofi Theme Applied" "$(basename "$themeToPreviewNow" .rasi)"
    break
  else # Error or unexpected exit code
    notify_user "$iconsDir/error.svg" "Rofi Error" "Unexpected Rofi exit ($rofiExitCode). Reverting."
    echo "$originalRofiFileContentBackup" >"$rofiConfigFile"
    break
  fi
done

exit 0
