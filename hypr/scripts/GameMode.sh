#!/usr/bin/env bash
# gamemode.sh
# Toggles "game mode": stops background services that compete for CPU/GPU/RAM,
# silences notifications, and disables hypridle so the screen doesn't lock/dim
# mid-game. Run again to revert everything.

GAME_MODE_LOCATION="${HOME}/.config/hypr/scripts/gamemode_status"
notif="$HOME/.local/share/icons/breeze-dark-accent/apps/scalable/gaming.svg"
mkdir -p "${HOME}/.config/hypr/scripts"

if [ ! -f "${GAME_MODE_LOCATION}" ]; then
    echo "false" > "${GAME_MODE_LOCATION}"
fi

unit_exists() {
    systemctl --user cat "$1" >/dev/null 2>&1 || systemctl cat "$1" >/dev/null 2>&1
}

# Add new services here as "label:unit1,unit2" — units are comma-separated,
# no spaces. Label is just what shows up in the notification text.
GAME_MODE_SERVICES=(
    "docker:docker.socket,docker.service"
    "ollama:ollama.service"
    "waybar:waybar.service"
)

GAME_MODE_UNITS=""
GAME_MODE_UNITS_DESC=""

for entry in "${GAME_MODE_SERVICES[@]}"; do
    label="${entry%%:*}"
    units="${entry#*:}"
    found=false

    IFS=',' read -ra unit_list <<< "$units"
    for u in "${unit_list[@]}"; do
        if unit_exists "$u"; then
            GAME_MODE_UNITS="${GAME_MODE_UNITS}${GAME_MODE_UNITS:+ }$u"
            found=true
        fi
    done

    if [ "$found" = true ]; then
        GAME_MODE_UNITS_DESC="${GAME_MODE_UNITS_DESC}${GAME_MODE_UNITS_DESC:+, }$label"
    fi
done

enable_notif_inhibit() {
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        swaync-client --dnd-on >/dev/null 2>&1
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        for app in coolercontrol plasma_workspace powerdevil networkmanagement; do
            kwriteconfig6 --file plasmanotifyrc --group "Applications" --group "$app" --key "ShowInDoNotDisturbMode" true >/dev/null 2>&1
        done
        qdbus6 org.kde.plasmashell /org/kde/osdService org.kde.osdService.dndEnabled true >/dev/null 2>&1
    fi
}

disable_notif_inhibit() {
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        swaync-client --dnd-off >/dev/null 2>&1
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        qdbus6 org.kde.plasmashell /org/kde/osdService org.kde.osdService.dndEnabled false >/dev/null 2>&1
    fi
}

CURRENT_STATE=$(cat "${GAME_MODE_LOCATION}" 2>/dev/null || echo "false")

if [ "${CURRENT_STATE}" = "false" ]; then
    echo "true" > "${GAME_MODE_LOCATION}"

    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl reload >/dev/null 2>&1
        if pgrep -x "hypridle" >/dev/null; then
            pkill hypridle
        fi
    fi

    if [ -n "$GAME_MODE_UNITS" ]; then
        systemctl stop $GAME_MODE_UNITS >/dev/null 2>&1
    fi

    notify-send -e -u low -i "$notif" "Gamemode: enabled" "${GAME_MODE_UNITS_DESC:-nothing to stop} off"
    sleep 10 && enable_notif_inhibit
else
    echo "false" > "${GAME_MODE_LOCATION}"

    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl reload >/dev/null 2>&1
        if ! pgrep -x "hypridle" >/dev/null; then
            hypridle &
        fi
    fi

    if [ -n "$GAME_MODE_UNITS" ]; then
        systemctl start $GAME_MODE_UNITS >/dev/null 2>&1
    fi

    disable_notif_inhibit
    notify-send -e -u low -i "$notif" "Gamemode: disabled" "${GAME_MODE_UNITS_DESC:-nothing to start} on"
fi