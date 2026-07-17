#!/usr/bin/env bash
# spicetifyPostHook.sh
# Wraps the spicetify "reload" post_hook so matugen's [templates.spotify]
# entry doesn't hang/error out the whole matugen run when Spotify isn't
# installed. Meant to be called directly as matugen's post_hook, e.g.:
#
#   [templates.spotify]
#   input_path = 'path/to/spicetify-color-template.ini'
#   output_path = '~/.config/spicetify/Themes/Sleek/color.ini'
#   post_hook = '~/.config/WallpaperChanger/themeRefresherSupportScripts/appPatchers/spicetifyPostHook.sh'
#
# Always exits 0 when Spotify isn't found (a skip, not a failure) so matugen
# doesn't log/treat it as a broken hook.

set -uo pipefail

# Same best-effort multi-method detection used in install.sh's
# "Configure Spicetify" section and dependency_check.sh — won't catch every
# install method (snap, AUR spotify-launcher wrappers, etc.), but covers the
# common native/flatpak cases.
_has_spotify() {
    command -v spotify &>/dev/null && return 0
    [ -d "/opt/spotify" ] && return 0
    flatpak info com.spotify.Client &>/dev/null 2>&1 && return 0
    return 1
}

if ! command -v spicetify &>/dev/null; then
    echo "spicetifyPostHook: spicetify not found on PATH, skipping."
    exit 0
fi

if ! _has_spotify; then
    echo "spicetifyPostHook: Spotify not detected, skipping spicetify reload."
    exit 0
fi

if pgrep -x spotify &>/dev/null; then
    # spicetify apply/watch expects to patch Spotify's own files; doing that
    # while Spotify is running is the actual source of the "lots of issues"
    # behavior — not just a missing-Spotify problem. Skip rather than risk a
    # half-applied patch.
    echo "spicetifyPostHook: Spotify is currently running, skipping spicetify reload."
    echo "Close Spotify and run 'spicetify apply' manually to pick up the new colors."
    exit 0
fi

spicetify watch -s 2>&1 | sed "/Reloaded Spotify/q"
