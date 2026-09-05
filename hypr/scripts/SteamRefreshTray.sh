#!/usr/bin/env bash
# SteamRefreshTray
# Launches Steam minimized, waits for its tray icon to register on
# D-Bus, then runs ThemeRefresher.sh --tray and exits.

set -uo pipefail

ThemeRefresher="$HOME/.config/WallpaperChanger/ThemeRefresher.sh"
debug="${DEBUG:-0}"

log() { [[ "$debug" == "1" ]] && echo "[debug] $*" >&2; }

# Abort early if either dependency is missing.
check_requirements() {
    command -v steam >/dev/null 2>&1 \
        || { echo "steam not found in PATH" >&2; exit 1; }
    [[ -x "$ThemeRefresher" ]] \
        || { echo "ThemeRefresher.sh missing or not executable: $ThemeRefresher" >&2; exit 1; }
}

wait_for_steam_tray() {
    # coproc (not process substitution) gives a real PID we can kill
    # outright — $! isn't reliably set after `<(cmd)` across bash versions.
    coproc DBUSMON {
        dbus-monitor --session \
            "interface='org.kde.StatusNotifierWatcher',member='RegisterStatusNotifierItem'" 2>/dev/null
    }
    dbusMonPid="$DBUSMON_PID"

    while IFS= read -r line <&"${DBUSMON[0]}"; do
        log "line: $line"
        [[ "$line" == method\ call* ]] || continue

        senderId=$(grep -oP 'sender=\K:[0-9.]+' <<< "$line")
        [[ -z "$senderId" ]] && continue

        # Resolve the actual caller PID so we react only to Steam,
        # not some unrelated app registering its own tray icon.
        callerPid=$(dbus-send --session --print-reply \
            --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus \
            org.freedesktop.DBus.GetConnectionUnixProcessID \
            "string:${senderId}" 2>&1 | awk '/uint32/{print $2}')
        [[ -z "$callerPid" ]] && continue

        callerComm=$(cat "/proc/${callerPid}/comm" 2>/dev/null || echo "?")
        log "callerPid=$callerPid callerComm=$callerComm"

        if grep -qi steam <<< "$callerComm"; then
            echo "Steam tray icon registered (PID $callerPid)." >&2
            break
        fi
    done

    # Stop dbus-monitor now — it's no longer needed and must not linger.
    kill "$dbusMonPid" 2>/dev/null
    wait "$dbusMonPid" 2>/dev/null
}

check_requirements

steam -silent &
steamPid=$!
echo "Steam started minimized (PID $steamPid). Waiting for tray icon..." >&2

wait_for_steam_tray

"$ThemeRefresher" --tray
exit $?