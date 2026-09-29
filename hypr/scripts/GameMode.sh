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


# Writes a default GameModeProcesses file the first time GameMode runs, so the
# script is usable out of the box and self-documenting.
create_default_processes_file() {
    cat > "${gameModeProcessesFile}" << 'EOF'
# GameMode process list
#
# One entry per line. Blank lines and lines starting with # are ignored.
# Trailing "# comment" after an entry is also stripped.
#
# Three entry types are supported:
#
#   unit:label:unit1,unit2,...
#       systemd units (user- or system-scope, auto-detected). Comma-separated,
#       no spaces. This is the original behaviour — the whole unit gets
#       stopped/started, e.g. the entire docker daemon.
#
#   docker:label:container1,container2,...
#       Plain containers, stopped/started directly by name via
#       `docker stop`/`docker start` — works regardless of how the
#       container was created, but doesn't recreate anything, so this is
#       only for containers you don't need `compose up` semantics for.
#
#   compose:label:/absolute/path/to/docker-compose.yml:service1,service2,...
#       Containers managed by a specific compose file, stopped/started via
#       `docker compose -f <file> stop/start <service>`. Use this for
#       containers that live in a stack with other services you want left
#       running, or where the compose file's env/network context matters.
#
# label is just what shows up in the notification text.
#
# Examples:
unit:docker daemon:docker.socket,docker.service
unit:ollama:ollama.service
unit:waybar:waybar.service
# compose:odysseus:/home/fc3243d4/odysseus/docker-compose.yml:app,worker
# docker:comfyui:comfyui-container
EOF
}

variables_initialization() {
    gameModeLocation="${HOME}/.config/hypr/scripts/gamemode_status"
    previousPowerProfile="${HOME}/.config/hypr/scripts/power_profile"
    notif="$HOME/.local/share/icons/breeze-dark-accent/apps/scalable/gaming.svg"
    gameModeProcessesFile="${HOME}/.config/hypr/scripts/GameModeProcesses"
    mkdir -p "${HOME}/.config/hypr/scripts"
    gameModeUnits=""              # system-scope systemd units
    gameModeUserUnits=""          # user-scope systemd units
    gameModeDockerContainers=""   # plain containers (docker stop/start by name)
    gameModeComposeFiles=()       # parallel array: compose file per compose entry
    gameModeComposeServices=()    # parallel array: space-separated services per compose entry
    gameModeUserUnitsDescending=""

    # Create the status file if it doesn't exist, defaulting to "false" (game mode off).
    if [ ! -f "${gameModeLocation}" ]; then
        echo "false" > "${gameModeLocation}"
    fi

    # Populates current state
    currentState=$(cat "${gameModeLocation}" 2>/dev/null || echo "false")

    # Create the processes file with sane defaults on first run.
    if [ ! -f "${gameModeProcessesFile}" ]; then
        create_default_processes_file
    fi

    # Parse the processes file into the unit/docker/compose lists above.
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"                                   # strip comments
        line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"  # trim
        [ -z "$line" ] && continue

        entryType="${line%%:*}"
        rest="${line#*:}"
        label="${rest%%:*}"
        rest="${rest#*:}"

        case "$entryType" in
            unit)
                units="$rest"
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
                ;;
            docker)
                containers="${rest//,/ }"
                gameModeDockerContainers="${gameModeDockerContainers}${gameModeDockerContainers:+ }${containers}"
                gameModeUserUnitsDescending="${gameModeUserUnitsDescending}${gameModeUserUnitsDescending:+, }$label"
                ;;
            compose)
                composeFile="${rest%%:*}"
                services="${rest#*:}"
                if [ -f "$composeFile" ]; then
                    gameModeComposeFiles+=("$composeFile")
                    gameModeComposeServices+=("${services//,/ }")
                    gameModeUserUnitsDescending="${gameModeUserUnitsDescending}${gameModeUserUnitsDescending:+, }$label"
                else
                    echo "GameMode: compose file not found, skipping '$label': $composeFile" >&2
                fi
                ;;
            *)
                echo "GameMode: unknown entry type '$entryType' in ${gameModeProcessesFile}, skipping" >&2
                ;;
        esac
    done < "${gameModeProcessesFile}"
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

# Docker/compose helpers. Try unprivileged first (works when the user is in
# the `docker` group, which is the normal setup). If that fails — most
# commonly because the user *isn't* in the docker group and the daemon
# socket is root-only — fall back to pkexec/sudo based on $1 ("polkit" or
# "no-polkit"), same as the systemd unit handling below.
stop_docker_workloads() {
    local mode="$1"
    if [ -n "$gameModeDockerContainers" ]; then
        if ! docker stop $gameModeDockerContainers >/dev/null 2>&1; then
            if [ "$mode" = "polkit" ]; then
                pkexec docker stop $gameModeDockerContainers >/dev/null 2>&1
            else
                sudo docker stop $gameModeDockerContainers >/dev/null 2>&1
            fi
        fi
    fi
    for i in "${!gameModeComposeFiles[@]}"; do
        if ! docker compose -f "${gameModeComposeFiles[$i]}" stop ${gameModeComposeServices[$i]} >/dev/null 2>&1; then
            if [ "$mode" = "polkit" ]; then
                pkexec docker compose -f "${gameModeComposeFiles[$i]}" stop ${gameModeComposeServices[$i]} >/dev/null 2>&1
            else
                sudo docker compose -f "${gameModeComposeFiles[$i]}" stop ${gameModeComposeServices[$i]} >/dev/null 2>&1
            fi
        fi
    done
}

start_docker_workloads() {
    local mode="$1"
    if [ -n "$gameModeDockerContainers" ]; then
        if ! docker start $gameModeDockerContainers >/dev/null 2>&1; then
            if [ "$mode" = "polkit" ]; then
                pkexec docker start $gameModeDockerContainers >/dev/null 2>&1
            else
                sudo docker start $gameModeDockerContainers >/dev/null 2>&1
            fi
        fi
    fi
    for i in "${!gameModeComposeFiles[@]}"; do
        if ! docker compose -f "${gameModeComposeFiles[$i]}" start ${gameModeComposeServices[$i]} >/dev/null 2>&1; then
            if [ "$mode" = "polkit" ]; then
                pkexec docker compose -f "${gameModeComposeFiles[$i]}" start ${gameModeComposeServices[$i]} >/dev/null 2>&1
            else
                sudo docker compose -f "${gameModeComposeFiles[$i]}" start ${gameModeComposeServices[$i]} >/dev/null 2>&1
            fi
        fi
    done
}

# Polkit versions of the stop/start functions use pkexec to run systemctl as root. The user must have sudo privileges for the latter to work.
stop_services_polkit() {
    if [ -n "$gameModeUnits" ]; then
        pkexec systemctl stop $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user stop $gameModeUserUnits >/dev/null 2>&1
    fi
    stop_docker_workloads "polkit"
}

start_services_polkit() {
    if [ -n "$gameModeUnits" ]; then
        pkexec systemctl start $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user start $gameModeUserUnits >/dev/null 2>&1
    fi
    start_docker_workloads "polkit"
}

# No-polkit versions of the stop/start functions use sudo to run systemctl as root. The user must have sudo privileges for these to work.
stop_services_no_polkit() {
    if [ -n "$gameModeUnits" ]; then
        sudo systemctl stop $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user stop $gameModeUserUnits >/dev/null 2>&1
    fi
    stop_docker_workloads "no-polkit"
}

start_services_no_polkit() {
    if [ -n "$gameModeUnits" ]; then
        sudo systemctl start $gameModeUnits >/dev/null 2>&1
    fi
    if [ -n "$gameModeUserUnits" ]; then
        systemctl --user start $gameModeUserUnits >/dev/null 2>&1
    fi
    start_docker_workloads "no-polkit"
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