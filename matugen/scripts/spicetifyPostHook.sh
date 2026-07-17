#!/usr/bin/env bash
# spicetifyPostHook.sh
# Wraps the spicetify "reload" post_hook so matugen's [templates.spotify]
# entry doesn't hang/error out the whole matugen run when Spotify isn't
# installed, or when spicetify's own stored spotify_path is stale/wrong.
# Meant to be called directly as matugen's post_hook, e.g.:
#
#   [templates.spotify]
#   input_path = 'path/to/spicetify-color-template.ini'
#   output_path = '~/.config/spicetify/Themes/Sleek/color.ini'
#   post_hook = '~/.config/WallpaperChanger/themeRefresherSupportScripts/appPatchers/spicetifyPostHook.sh'
#
# Always exits 0 when Spotify/spicetify aren't usable (a skip, not a
# failure) so matugen doesn't log/treat it as a broken hook.

set -uo pipefail

# Finds Spotify's real install directory (the folder containing the actual
# `spotify` executable, which is what spicetify's spotify_path setting
# needs), regardless of where a PATH launcher/symlink points. This is
# BEST-EFFORT: install layouts vary a lot across distros/AUR/snap, and this
# only covers native installs — Flatpak Spotify isn't handled the same way
# by spicetify and is treated as "not found" here rather than guessed at.
_find_spotify_path() {
    local candidates=("/opt/spotify" "/usr/share/spotify" "/usr/lib/spotify-client")

    if command -v spotify &>/dev/null; then
        local resolved
        resolved="$(readlink -f "$(command -v spotify)" 2>/dev/null)"
        [ -n "$resolved" ] && candidates=("$(dirname "$resolved")" "${candidates[@]}")
    fi

    local dir
    for dir in "${candidates[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/spotify" ]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

if ! command -v spicetify &>/dev/null; then
    echo "spicetifyPostHook: spicetify not found on PATH, skipping."
    exit 0
fi

spotify_dir="$(_find_spotify_path)"
if [ -z "$spotify_dir" ]; then
    echo "spicetifyPostHook: couldn't find a native Spotify install (checked PATH,"
    echo "/opt/spotify, /usr/share/spotify, /usr/lib/spotify-client). If you're on"
    echo "Flatpak/Snap Spotify, spicetify needs manual setup for that — see"
    echo "https://spicetify.app for your install method. Skipping."
    exit 0
fi

# Spotify creates its own "prefs" file the first time it's actually launched
# (not on install) — spicetify needs it to exist before it can patch
# anything. A fresh, never-opened install doesn't have it yet, and that's a
# real, separate failure from "spotify_path was wrong": spicetify errors
# with "cannot detect spotify \"prefs\" file location" instead. Not
# something to work around by launching Spotify headlessly from a post_hook
# (fragile, could hang or pop a window) — just skip cleanly until the user
# has opened Spotify at least once.
SPOTIFY_PREFS="$HOME/.config/spotify/prefs"
if [ ! -f "$SPOTIFY_PREFS" ]; then
    echo "spicetifyPostHook: Spotify is installed but has never been launched"
    echo "(no $SPOTIFY_PREFS yet). Open Spotify once, then re-run to enable theming."
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

# Keep spicetify's own config-xpui.ini in sync with the real paths rather
# than trusting whatever it currently has stored (this is what was actually
# causing "/opt/spotify is not a valid path" — a stale/wrong stored value,
# not merely Spotify being absent).
if ! spicetify config spotify_path "$spotify_dir" &>/dev/null; then
    echo "spicetifyPostHook: 'spicetify config spotify_path $spotify_dir' failed. Skipping."
    exit 0
fi
if ! spicetify config prefs_path "$SPOTIFY_PREFS" &>/dev/null; then
    echo "spicetifyPostHook: 'spicetify config prefs_path $SPOTIFY_PREFS' failed. Skipping."
    exit 0
fi

# spicetify watch -s | sed "/Reloaded Spotify/q" (the upstream-suggested
# one-shot trick) is NOT actually one-shot: `watch` is a persistent mode that
# waits for a running Spotify instance to reload, and by this point in the
# script Spotify is confirmed NOT running (see the pgrep check above) - so
# there's nothing for it to watch, and it blocks forever, taking matugen's
# entire run down with it. `spicetify apply` is what we actually want: a
# synchronous, one-shot patch that returns regardless of whether Spotify is
# running. The timeout is a second safety net in case it ever hangs for an
# unrelated reason (e.g. a stuck lock file) - a stalled post_hook should
# never be able to stall the rest of matugen's run.
timeout 30 spicetify apply
status=$?
if [ "$status" -ne 0 ]; then
    if [ "$status" -eq 124 ]; then
        echo "spicetifyPostHook: 'spicetify apply' timed out after 30s — skipping."
    else
        echo "spicetifyPostHook: 'spicetify apply' failed (exit $status) — skipping."
    fi
fi