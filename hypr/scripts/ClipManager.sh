#!/usr/bin/env bash
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Variables
scriptsDir="$HOME/.config/hypr/scripts"
rofiTheme="$HOME/.config/rofi/config-clipboard.rasi"
msg='CTRL DEL = cliphist del (entry)   or   ALT DEL - cliphist wipe (all)'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Scale window width to the focused monitor's aspect ratio
source "$scriptsDir/RofiWidthScale.sh"
rofiWidth=$(rofi_scaled_width)

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

while true; do
    result=$(
        rofi -i -dmenu \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -config $rofiTheme < <(cliphist list) \
			-mesg "$msg" \
			-theme-str "window { width: ${rofiWidth}%; }"
    )

    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<<"$result"
            ;;
        11)
            cliphist wipe
            ;;
    esac
done

