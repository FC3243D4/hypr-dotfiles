#!/usr/bin/env bash

if [ "$XDG_CURRENT_DESKTOP" != "Hyprland" ]; then
    exit 0
fi

while true; do
    if ! pgrep -x kded6 > /dev/null; then
        sleep 2
        continue
    fi

    if ! qdbus6 org.kde.kded6 /kded org.kde.kded6.loadedModules &>/dev/null; then
        sleep 0.5
        continue
    fi

    if qdbus6 org.kde.kded6 /kded org.kde.kded6.loadedModules 2>/dev/null | grep -q "statusnotifierwatcher"; then
        notify-send -i "kded6 stole SNI wather, killing it..."
        echo "kded6 stole SNI watcher, killing it..."
        pkill -x kded6
    fi

    while pgrep -x kded6 > /dev/null; do
        sleep 5
    done
done
