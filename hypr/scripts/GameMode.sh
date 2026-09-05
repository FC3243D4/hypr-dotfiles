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
    gameModeLocation="${HOME}/.config/hypr/scripts/gamemode_status"
    previousPowerProfile="${HOME}/.config/hypr/scripts/power_profile"
    notif="$HOME/.local/share/icons/breeze-dark-accent/apps/scalable/gaming.svg"
    mkdir -p "${HOME}/.config/hypr/scripts"
    gameModeUnits=""        # system-scope units
    gameModeUserUnits=""    # user-scope units
    gameModeUserUnitsDescending=""

    # Add new services here as "label:unit1,unit2" — units are comma-separated,
    # no spaces. Label is just what shows up in the notification text.
    gameModeServices=(
        "docker:docker.socket,docker.service"
        "ollama:ollama.service"
        "waybar:waybar.service"
    )

    # Create the status file if it doesn't exist, defaulting to "false" (game mode off).
    if [ ! -f "${gameModeLocation}" ]; then
        echo "false" > "${gameModeLocation}"
    fi

    # Populates current state
    currentState=$(cat "${gameModeLocation}" 2>/dev/null || echo "false")

    # Populate the list of units to stop/start based on what actually exists on this system.
    for entry in "${gameModeServices[@]}"; do
        label="${entry%%:*}"
        units="${entry#*:}"
        found=false

        IFS=',' read -ra unit_list <<< "$units"
        for u in "${unit_list[@]}"; do
            scope=$(unit_scope "$u")
            case "$scope" in
                user)
                    gameModeUserUnits="${gameModeUserUnits}${gameModeUserUnits:+ }$u"
                    found=true
                    ;;
                system)
                    gameModeUnits="${gameModeUnits}${gameModeUnits:+ }$u"
                    found=true
                    ;;
            esac
        done

        if [ "$found" = true ]; then
            gameModeUserUnitsDescending="${gameModeUserUnitsDescending}${gameModeUserUnitsDescending:+, }$label"
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
    if [ -n "$gameModeUnits" ]; then
        pkexec systemctl stop $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user stop $gameModeUserUnits >/dev/null 2>&1
    fi
}

start_services_polkit() {
    if [ -n "$gameModeUnits" ]; then
        pkexec systemctl start $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user start $gameModeUserUnits >/dev/null 2>&1
    fi
}

# No-polkit versions of the stop/start functions use sudo to run systemctl as root. The user must have sudo privileges for these to work.
stop_services_no_polkit() {
    if [ -n "$gameModeUnits" ]; then
        sudo systemctl stop $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user stop $gameModeUserUnits >/dev/null 2>&1
    fi
}

start_services_no_polkit() {
    if [ -n "$gameModeUnits" ]; then
        sudo systemctl start $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user start $gameModeUserUnits >/dev/null 2>&1
    fi
}


main() {

    if [ "$1" != "polkit" ] && [ "$1" != "no-polkit" ]; then
        echo "invalid argument: $1"
        exit 1
    fi

    variables_initialization
    if [ "${currentState}" = "false" ]; then
        echo "true" > "${gameModeLocation}"
        echo "$(powerprofilesctl get)" > "${previousPowerProfile}"
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

        notify-send -e -u low -i "$notif" "Gamemode: enabled" "${gameModeUserUnitsDescending:-nothing to stop} off"
        sleep 10 && enable_notif_inhibit
    else
        disable_notif_inhibit
        echo "false" > "${gameModeLocation}"
        powerprofilesctl set "$(cat "${previousPowerProfile}")"

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

        notify-send -e -u low -i "$notif" "Gamemode: disabled" "${gameModeUserUnitsDescending:-nothing to start} on"
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