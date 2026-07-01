#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds so they always cycle windows globally (no layout-specific behavior)
# This avoids double-actions when layouts change.

set -euo pipefail

# Always reset and bind SUPER+J/K the same way on startup.
# Note: hyprctl keyword bind/unbind use the runtime keyword API (not config file syntax)
# and remain valid in 0.55 — the argument format is "MOD, KEY, dispatcher[, params]"
hyprctl keyword unbind "SUPER, J" || true
hyprctl keyword unbind "SUPER, K" || true

# Cycle windows globally: J = next, K = previous
hyprctl keyword bind "SUPER, J, cyclenext"
hyprctl keyword bind "SUPER, K, cyclenext, prev"