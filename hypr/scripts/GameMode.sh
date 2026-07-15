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

# Prints "user" or "system" on stdout if the unit exists in that scope, empty (and exit 1) otherwise.
unit_scope() {
    if systemctl --user cat "$1" >/dev/null 2>&1; then
        echo "user"
    elif systemctl cat "$1" >/dev/null 2>&1; then
        echo "system"
    else
        return 1
    fi
}

# Add new services here as "label:unit1,unit2" — units are comma-separated,
# no spaces. Label is just what shows up in the notification text.
GAME_MODE_SERVICES=(
    "docker:docker.socket,docker.service"
    "ollama:ollama.service"
    "waybar:waybar.service"
)

GAME_MODE_UNITS=""        # system-scope units
GAME_MODE_USER_UNITS=""   # user-scope units
GAME_MODE_UNITS_DESC=""

for entry in "${GAME_MODE_SERVICES[@]}"; do
    label="${entry%%:*}"
    units="${entry#*:}"
    found=false

    IFS=',' read -ra unit_list <<< "$units"
    for u in "${unit_list[@]}"; do
        scope=$(unit_scope "$u")
        case "$scope" in
            user)
                GAME_MODE_USER_UNITS="${GAME_MODE_USER_UNITS}${GAME_MODE_USER_UNITS:+ }$u"
                found=true
                ;;
            system)
                GAME_MODE_UNITS="${GAME_MODE_UNITS}${GAME_MODE_UNITS:+ }$u"
                found=true
                ;;
        esac
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
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user stop $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi

    awww kill

    notify-send -e -u low -i "$notif" "Gamemode: enabled" "${GAME_MODE_UNITS_DESC:-nothing to stop} off"
    sleep 10 && enable_notif_inhibit
else
    echo "false" > "${GAME_MODE_LOCATION}"

    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl reload >/dev/null 2>&1
        if ! pgrep -x "hypridle" >/dev/null; then
            hypridle &
        fi
        awww-daemon &
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        awww-daemon --layer bottom &
    fi

    if [ -n "$GAME_MODE_UNITS" ]; then
        systemctl start $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user start $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi

    $HOME/.config/WallpaperChanger/WallpaperApplicator.sh random

    disable_notif_inhibit
    notify-send -e -u low -i "$notif" "Gamemode: disabled" "${GAME_MODE_UNITS_DESC:-nothing to start} on"
fi