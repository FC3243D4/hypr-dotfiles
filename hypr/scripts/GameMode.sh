#!/bin/sh
GAME_MODE_LOCATION="${HOME}/.config/hypr/scripts/gamemode_status"
mkdir -p "${HOME}/.config/hypr/scripts"
if [ ! -f "${GAME_MODE_LOCATION}" ]; then
    echo "false" > "${GAME_MODE_LOCATION}"
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
    systemctl stop docker.socket docker ollama >/dev/null 2>&1
    enable_notif_inhibit
    notify-send -e -u low -i "$notif" "Gamemode: enabled" "docker off"
else
    echo "false" > "${GAME_MODE_LOCATION}"
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl reload >/dev/null 2>&1
        if ! pgrep -x "$PROCESS" >/dev/null; then
            hypridle &
        fi
    fi
    systemctl start docker.socket docker ollama >/dev/null 2>&1
    disable_notif_inhibit
    notify-send -e -u low -i "$notif" "Gamemode: disabled" "docker on"
fi
