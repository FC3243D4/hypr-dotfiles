#!/usr/bin/env bash

if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
    kwriteconfig6 --file kded6rc --group "Module-statusnotifierwatcher" --key "autoload" "false"
    kwriteconfig6 --file kded6rc --group "Module-statusnotifieritem" --key "autoload" "false"
    kwriteconfig6 --file kded6rc --group "Module-xembedsniproxy" --key "autoload" "false"

    # Restart kded6 so it picks up the new config
    pkill -x kded6
    sleep 1
    /usr/bin/kded6 &
    disown
    sleep 1

    # Force unload even if something requested it
    qdbus6 org.kde.kded6 /kded org.kde.kded6.unloadModule statusnotifierwatcher 2>/dev/null
    qdbus6 org.kde.kded6 /kded org.kde.kded6.unloadModule statusnotifieritem 2>/dev/null
    qdbus6 org.kde.kded6 /kded org.kde.kded6.unloadModule xembedsniproxy 2>/dev/null
else
    kwriteconfig6 --file kded6rc --group "Module-statusnotifierwatcher" --key "autoload" "true"
    kwriteconfig6 --file kded6rc --group "Module-statusnotifieritem" --key "autoload" "true"
    kwriteconfig6 --file kded6rc --group "Module-xembedsniproxy" --key "autoload" "true"
fi