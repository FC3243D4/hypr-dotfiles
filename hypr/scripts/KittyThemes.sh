#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Kitty Themes Source https://github.com/dexpota/kitty-themes #

# Define directories and variables
kittyThemesDirectory="$HOME/.config/kitty/kitty-themes" # Kitty Themes Directory
kittyConfig="$HOME/.config/kitty/kitty.conf"
iconsDirectory="$HOME/.config/swaync/icons" # For notifications
rofiThemeForThisScript="$HOME/.config/rofi/config-kitty-theme.rasi"

# --- Helper Functions ---
notify_user() {
  notify-send -u low -i "$1" "$2" "$3"
}

# Function to apply the selected kitty theme
apply_kitty_theme_to_config() {
  local themeNameToApply="$1"
  if [ -z "$themeNameToApply" ]; then
    echo "Error: No theme name provided to apply_kitty_theme_to_config." >&2
    return 1
  fi

  local themeFilePathToApply="$kittyThemesDirectory/$themeNameToApply.conf"
  if [ ! -f "$themeFilePathToApply" ]; then
    notify_user "$iconsDirectory/error.svg" "Error" "Theme file not found: $themeNameToApply.conf"
    return 1
  fi

  local tempKittyConfigFile
  tempKittyConfigFile=$(mktemp)
  cp "$kittyConfig" "$tempKittyConfigFile"

  if grep -q -E '^[#[:space:]]*include\s+\./kitty-themes/.*\.conf' "$tempKittyConfigFile"; then
    sed -i -E "s|^([#[:space:]]*include\s+\./kitty-themes/).*\.conf|include ./kitty-themes/$themeNameToApply.conf|g" "$tempKittyConfigFile"
  else
    if [ -s "$tempKittyConfigFile" ] && [ "$(tail -c1 "$tempKittyConfigFile")" != "" ]; then
      echo >>"$tempKittyConfigFile"
    fi
    echo "include ./kitty-themes/$themeNameToApply.conf" >>"$tempKittyConfigFile"
  fi

  cp "$tempKittyConfigFile" "$kittyConfig"
  rm "$tempKittyConfigFile"

  for pid_kitty in $(pidof kitty); do
    if [ -n "$pid_kitty" ]; then
      kill -SIGUSR1 "$pid_kitty"
    fi
  done
  return 0
}

# --- Main Script Execution ---

if [ ! -d "$kittyThemesDirectory" ]; then
  notify_user "$iconsDirectory/error.svg" "E-R-R-O-R" "Kitty Themes directory not found: $kittyThemesDirectory"
  exit 1
fi

if [ ! -f "$rofiThemeForThisScript" ]; then
  notify_user "$iconsDirectory/error.svg" "Rofi Config Missing" "Rofi theme for Kitty selector not found at: $rofiThemeForThisScript."
  exit 1
fi

originalKittyConfigContentBackup=$(cat "$kittyConfig")

mapfile -t availableThemesName < <(find "$kittyThemesDirectory" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort)

if [ ${#availableThemesName[@]} -eq 0 ]; then
  notify_user "$iconsDirectory/error.svg" "No Kitty Themes" "No .conf files found in $kittyThemesDirectory."
  exit 1
fi

currentSelectionIndex=0
currentActiveThemeName=$(awk -F'include ./kitty-themes/|\\.conf' '/^[[:space:]]*include \.\/kitty-themes\/.*\.conf/{print $2; exit}' "$kittyConfig")

if [ -n "$currentActiveThemeName" ]; then
  for i in "${!availableThemesName[@]}"; do
    if [[ "${availableThemesName[$i]}" == "$currentActiveThemeName" ]]; then
      currentSelectionIndex=$i
      break
    fi
  done
fi

while true; do
  themeToPreviewNow="${availableThemesName[$currentSelectionIndex]}"

  if ! apply_kitty_theme_to_config "$themeToPreviewNow"; then
    echo "$originalKittyConfigContentBackup" >"$kittyConfig"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    notify_user "$iconsDirectory/error.svg" "Preview Error" "Failed to apply $themeToPreviewNow. Reverted."
    exit 1
  fi

  rofiInputList=""
  for themeNameInList in "${availableThemesName[@]}"; do
    rofiInputList+="$themeNameInList\n"
  done
  rofiInputListTrimmed="${rofiInputList%\\n}"

  chosenIndexFromRofi=$(echo -e "$rofiInputListTrimmed" |
    rofi -dmenu -i \
      -format 'i' \
      -p "Kitty Theme" \
      -mesg "Preview: ${themeToPreviewNow} | Enter: Preview | Ctrl+S: Apply & Exit | Esc: Cancel" \
      -config "$rofiThemeForThisScript" \
      -selected-row "$currentSelectionIndex" \
      -kb-custom-1 "Control+s") # MODIFIED HERE: Changed to Control+s for custom action 1

  rofiExitCode=$?

  if [ $rofiExitCode -eq 0 ]; then
    if [[ "$chosenIndexFromRofi" =~ ^[0-9]+$ ]] && [ "$chosenIndexFromRofi" -lt "${#availableThemesName[@]}" ]; then
      currentSelectionIndex="$chosenIndexFromRofi"
    else
      :
    fi
  elif [ $rofiExitCode -eq 1 ]; then
    notify_user "$iconsDirectory/note.svg" "Kitty Theme" "Selection cancelled. Reverting to original theme."
    echo "$originalKittyConfigContentBackup" >"$kittyConfig"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  elif [ $rofiExitCode -eq 10 ]; then # This is the exit code for -kb-custom-1
    notify_user "$iconsDirectory/ok.svg" "Kitty Theme Applied" "$themeToPreviewNow"
    break
  else
    notify_user "$iconsDirectory/error.svg" "Rofi Error" "Unexpected Rofi exit ($rofiExitCode). Reverting."
    echo "$originalKittyConfigContentBackup" >"$kittyConfig"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  fi
done

exit 0
