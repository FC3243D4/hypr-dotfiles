#!/bin/sh
GAME_MODE_LOCATION="${HOME}/.config/hypr/scripts/gamemode_status"
notif="$HOME/.local/share/icons/breeze-dark-accent/apps/scalable/gaming.svg"
mkdir -p "${HOME}/.config/hypr/scripts"
if [ ! -f "${GAME_MODE_LOCATION}" ]; then
    echo "false" > "${GAME_MODE_LOCATION}"
fi

unit_exists() {
    systemctl cat "$1" >/dev/null 2>&1
}

# Build the list of service units to stop/start, limited to whichever of
# docker/ollama are actually installed on this machine.
GAME_MODE_UNITS=""
GAME_MODE_UNITS_DESC=""
for u in docker.socket docker.service ollama.service; do
    if unit_exists "$u"; then
        GAME_MODE_UNITS="${GAME_MODE_UNITS}${GAME_MODE_UNITS:+ }$u"
    fi
done
if unit_exists docker.service; then
    GAME_MODE_UNITS_DESC="docker"
fi
if unit_exists ollama.service; then
    GAME_MODE_UNITS_DESC="${GAME_MODE_UNITS_DESC}${GAME_MODE_UNITS_DESC:+, }ollama"
fi

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
        if pgrep -x "$PROCESS" >/dev/null; then
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
        if ! pgrep -x "$PROCESS" >/dev/null; then
            hypridle &
        fi
    fi
    if [ -n "$GAME_MODE_UNITS" ]; then
        systemctl start $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    disable_notif_inhibit
    notify-send -e -u low -i "$notif" "Gamemode: disabled" "${GAME_MODE_UNITS_DESC:-nothing to start} on"
fi