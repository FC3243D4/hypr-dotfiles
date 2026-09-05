#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for waybar styles

IFS=$'\n\t'

# Define directories
waybarStyles="$HOME/.config/waybar/style"
waybarStyle="$HOME/.config/waybar/style.css"
scriptsDir="$HOME/.config/hypr/scripts"
rofiConfig="$HOME/.config/rofi/config-waybar-style.rasi"
msg=' 🎌 NOTE: Some waybar STYLES NOT fully compatible with some LAYOUTS'

# Apply selected style
apply_style() {
    ln -sf "$waybarStyles/$1.css" "$waybarStyle"
    systemctl --user restart waybar
    echo "Applied style: $1"
}

main() {
    # resolve current symlink and strip .css
    currentTarget=$(readlink -f "$waybarStyle")
    currentName=$(basename "$currentTarget" .css)

    # gather all style names (without .css) into an array
    mapfile -t options < <(
        find -L "$waybarStyles" -maxdepth 1 -type f -name '*.css' \
            -exec basename {} .css \; \
            | sort
    )

    # mark the active style and record its index
    defaultRow=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$currentName" ]]; then
            options[i]="$MARKER ${options[i]}"
            defaultRow=$i
            break
        fi
    done

    # launch rofi with the annotated list and pre‑selected row
    choice=$(printf '%s\n' "${options[@]}" \
        | rofi -i -dmenu \
               -config "$rofiConfig" \
               -mesg "$msg" \
               -selected-row "$defaultRow"
    )

    [[ -z "$choice" ]] && { echo "No option selected. Exiting."; exit 0; }

    # remove annotation and apply
    choice=${choice#"$MARKER "}
    apply_style "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

main
