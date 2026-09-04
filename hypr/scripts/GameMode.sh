#!/usr/bin/env bash
# GameMode.sh
# Toggles "game mode": stops background services that compete for CPU/GPU/RAM,
# silences notifications, and disables hypridle so the screen doesn't lock/dim
# mid-game. Run again to revert everything.

usage() {
    cat << EOF
Usage: ./GameMode.sh [OPTION]

Options:
    --polkit            Runs using a polkit agent to avoid needing a terminal window (e.g. when launched from a keybind)
    --no-polkit         Runs without a polkit agent (e.g. when launched from a terminal)
    --help              Show this help message
EOF
}

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

variables_initialization() {
    GAME_MODE_LOCATION="${HOME}/.config/hypr/scripts/gamemode_status"
    PREVIOUS_POWER_PROFILE="${HOME}/.config/hypr/scripts/power_profile"
    notif="$HOME/.local/share/icons/breeze-dark-accent/apps/scalable/gaming.svg"
    mkdir -p "${HOME}/.config/hypr/scripts"
    GAME_MODE_UNITS=""        # system-scope units
    GAME_MODE_USER_UNITS=""   # user-scope units
    GAME_MODE_UNITS_DESC=""

    # Add new services here as "label:unit1,unit2" — units are comma-separated,
    # no spaces. Label is just what shows up in the notification text.
    GAME_MODE_SERVICES=(
        "docker:docker.socket,docker.service"
        "ollama:ollama.service"
        "waybar:waybar.service"
    )

    # Create the status file if it doesn't exist, defaulting to "false" (game mode off).
    if [ ! -f "${GAME_MODE_LOCATION}" ]; then
        echo "false" > "${GAME_MODE_LOCATION}"
    fi

    # Populates current state
    CURRENT_STATE=$(cat "${GAME_MODE_LOCATION}" 2>/dev/null || echo "false")

    # Populate the list of units to stop/start based on what actually exists on this system.
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
}

# Start the notification inhibition for the current desktop environment, if supported, disabling notifications while game mode is active. This is a best-effort attempt, and may not work in all DEs.
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

# Stop the notification inhibition for the current desktop environment, if supported, re-enabling notifications after game mode is disabled. This is a best-effort attempt, and may not work in all DEs.
disable_notif_inhibit() {
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        swaync-client --dnd-off >/dev/null 2>&1
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        qdbus6 org.kde.plasmashell /org/kde/osdService org.kde.osdService.dndEnabled false >/dev/null 2>&1
    fi
}

# Polkit versions of the stop/start functions use pkexec to run systemctl as root. The user must have sudo privileges for the latter to work.
stop_services_polkit() {
    if [ -n "$GAME_MODE_UNITS" ]; then
        pkexec systemctl stop $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user stop $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi
}

start_services_polkit() {
    if [ -n "$GAME_MODE_UNITS" ]; then
        pkexec systemctl start $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user start $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi
}

# No-polkit versions of the stop/start functions use sudo to run systemctl as root. The user must have sudo privileges for these to work.
stop_services_no_polkit() {
    if [ -n "$GAME_MODE_UNITS" ]; then
        sudo systemctl stop $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user stop $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi
}

start_services_no_polkit() {
    if [ -n "$GAME_MODE_UNITS" ]; then
        sudo systemctl start $GAME_MODE_UNITS >/dev/null 2>&1
    fi
    if [ -n "$GAME_MODE_USER_UNITS" ]; then
        systemctl --user start $GAME_MODE_USER_UNITS >/dev/null 2>&1
    fi
}


main() {

    if [ "$1" != "polkit" ] && [ "$1" != "no-polkit" ]; then
        echo "invalid argument: $1"
        exit 1
    fi

    variables_initialization
    if [ "${CURRENT_STATE}" = "false" ]; then
        echo "true" > "${GAME_MODE_LOCATION}"
        echo "$(powerprofilesctl get)" > "${PREVIOUS_POWER_PROFILE}"
        powerprofilesctl set performance

        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
            hyprctl reload >/dev/null 2>&1
            if pgrep -x "hypridle" >/dev/null; then
                pkill hypridle
            fi
        fi

        if [ "$1" = "polkit" ]; then
            stop_services_polkit
        elif [ "$1" = "no-polkit" ]; then
            stop_services_no_polkit
        fi

        awww kill

        notify-send -e -u low -i "$notif" "Gamemode: enabled" "${GAME_MODE_UNITS_DESC:-nothing to stop} off"
        sleep 10 && enable_notif_inhibit
    else
        disable_notif_inhibit
        echo "false" > "${GAME_MODE_LOCATION}"
        powerprofilesctl set "$(cat "${PREVIOUS_POWER_PROFILE}")"

        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
            hyprctl reload >/dev/null 2>&1
            if ! pgrep -x "hypridle" >/dev/null; then
                hypridle &
            fi
            awww-daemon &
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
            awww-daemon --layer bottom &
        fi

        if [ "$1" = "polkit" ]; then
            start_services_polkit
        elif [ "$1" = "no-polkit" ]; then
            start_services_no_polkit
        fi

        $HOME/.config/WallpaperChanger/WallpaperApplicator.sh random

        notify-send -e -u low -i "$notif" "Gamemode: disabled" "${GAME_MODE_UNITS_DESC:-nothing to start} on"
    fi
}

case "$1" in
    --polkit)
        main "polkit"
        ;;
    --no-polkit)
        main "no-polkit"
        ;;
    --help)
        usage
        exit 0
        ;;
    *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
esac