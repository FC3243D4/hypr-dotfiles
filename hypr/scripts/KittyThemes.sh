#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Vicinae-adapted Kitty Themes selector

# Define directories and variables
kittyThemesDirectory="$HOME/.config/kitty/kitty-themes"
kittyConfig="$HOME/.config/kitty/kitty.conf"
iconsDirectory="$HOME/.config/swaync/icons"

# --- Helper Functions ---
notify_user() {
  notify-send -u low -i "$1" "$2" "$3"
}

apply_kitty_theme_to_config() {
  local themeNameToApply="$1"
  if [ -z "$themeNameToApply" ]; then
    echo "Error: No theme name provided." >&2
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

mapfile -t availableThemesName < <(find "$kittyThemesDirectory" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort)

if [ ${#availableThemesName[@]} -eq 0 ]; then
  notify_user "$iconsDirectory/error.svg" "No Kitty Themes" "No .conf files found in $kittyThemesDirectory."
  exit 1
fi

# Build input list for vicinae dmenu
vicinaeInputList=""
for themeName in "${availableThemesName[@]}"; do
  vicinaeInputList+="$themeName\n"
done

chosenTheme=$(printf '%b' "$vicinaeInputList" | vicinae dmenu)

if [[ -n "$chosenTheme" ]]; then
  if apply_kitty_theme_to_config "$chosenTheme"; then
    notify_user "$iconsDirectory/ok.svg" "Kitty Theme Applied" "$chosenTheme"
  else
    notify_user "$iconsDirectory/error.svg" "Error" "Failed to apply $chosenTheme"
  fi
else
  notify_user "$iconsDirectory/note.svg" "Kitty Theme" "Selection cancelled."
fi

exit 0