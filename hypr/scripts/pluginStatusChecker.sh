#!/usr/bin/env bash
# pluginStatusChecker.sh
# Checks whether a given Hyprland plugin is actually loaded (not just built)
# and writes "true"/"false" to a status file for hyprland.lua to read.
#
# IMPORTANT: only run this when Hyprland is already fully up — e.g. from
# Startup_Apps (fires after startup completes) or manually after
# `hyprpm update`/`hyprpm reload`. Never call this synchronously from
# hyprland.lua itself: Hyprland re-sources the Lua config on its own main
# thread during any reload, so an hyprctl IPC call made mid-parse can
# deadlock waiting on the very reload that's waiting on the parse to finish.
#
# Usage: pluginStatusChecker.sh <plugin-name>
# Example: pluginStatusChecker.sh dynamic-cursors

plugin="$1"

if [ -z "$plugin" ]; then
    echo "Usage: $0 <plugin-name>" >&2
    exit 1
fi

statusDir="$HOME/.config/hypr/scripts"
mkdir -p "$statusDir"
statusFile="$statusDir/${plugin}_status"

if hyprctl plugin list 2>/dev/null | grep -qi "$plugin"; then
    echo "true" > "$statusFile"
    echo "$plugin: loaded"
else
    echo "false" > "$statusFile"
    echo "$plugin: not loaded"
fi
