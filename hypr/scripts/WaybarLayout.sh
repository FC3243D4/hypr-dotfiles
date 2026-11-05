#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for waybar layout or configs

IFS=$'\n\t'

# Define directories
waybarLayouts="$HOME/.config/waybar/configs"
waybarConfigs="$HOME/.config/waybar/config"
scriptsDir="$HOME/.config/hypr/scripts"
msg='Some waybar LAYOUT ARE NOT fully compatible with some STYLES'

# Apply selected configuration
apply_config() {
    ln -sf "$waybarLayouts/$1" "$waybarConfigs"
    systemctl --user restart waybar
    echo "Applied layout: $1"
}

main() {
    # Resolve current symlink target and basename
    currentTarget=$(readlink -f "$waybarConfigs")
    currentName=$(basename "$currentTarget")

    # Build sorted list of available layouts
    mapfile -t options < <(
        find -L "$waybarLayouts" -maxdepth 1 -type f -printf '%f\n' | sort
    )

    # Mark and locate the active layout
    defaultRow=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$currentName" ]]; then
            options[i]="$MARKER ${options[i]}"
            defaultRow=$i
            break
        fi
    done
    choice=$(printf '%s\n' "${options[@]}" | vicinae dmenu)

    # Exit if nothing chosen
    [[ -z "$choice" ]] && { echo "No option selected. Exiting."; exit 0; }

    # Strip marker before applying
    choice=${choice#"$MARKER "}

    case "$choice" in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

main