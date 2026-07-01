#!/usr/bin/env bash
# dependency_check.sh
# Checks for required dependencies and installs any that are missing.
# Meant to be SOURCED from install-Linux.sh (not executed) so that
# UseXrandr / UseWayland are visible to the caller.
#
# Returns 0 on success, 1 on failure (caller should check $? and stop).

source "$SUPPORT/pkg_manager.sh" || return 1

packageList=()

echo "Checking dependencies..."
if ! command -v rsync &>/dev/null; then
    echo "rsync"
    packageList+=("rsync")
fi
if ! matugen --version &> /dev/null; then
    echo "matugen"
    packageList+=("matugen")
fi
if ! waybar --version &> /dev/null; then
    echo "waybar"
    packageList+=("waybar")
fi
if ! command -v openrgb &>/dev/null; then
    echo "openrgb is not installed. You will not have the wallpaper's dominant color applied to your devices. Please install openrgb if you want this feature."
    echo ""
fi

# --- Display management (nwg-displays) ---
if ! command -v nwg-displays &>/dev/null; then
    echo "nwg-displays"
    packageList+=("nwg-displays")
fi

# --- Cursor theme compiler (accurse) ---
if ! command -v accurse &>/dev/null; then
    echo "accurse"
    packageList+=("accurse")
fi
if ! command -v rsvg-convert &>/dev/null; then
    echo "rsvg-convert"
    packageList+=("rsvg-convert")
fi
if ! command -v xcursorgen &>/dev/null; then
    echo "xcursorgen"
    packageList+=("xcursorgen")
fi

# --- KDE section ---
echo "Checking KDE dependencies..."

if ! command -v plasmashell &>/dev/null; then
    echo "plasmashell (KDE Plasma)"
    packageList+=("plasma-desktop")
fi

if ! command -v dolphin &>/dev/null; then
    echo "kde-applications"
    packageList+=("kde-applications")
fi

if ! command -v kwriteconfig6 &>/dev/null; then
    echo "kwriteconfig6"
    packageList+=("kconfig")
fi

if ! command -v plasma-apply-colorscheme &>/dev/null; then
    echo "plasma-apply-colorscheme"
    packageList+=("plasma-workspace")
fi

if (( ${#packageList[@]} == 0 )); then
    echo "All dependencies are already installed."
    return 0
fi

echo "The following packages are missing and will be installed:"
printf '  %s\n' "${packageList[@]}"
echo ""

sync_repos
if ! install_pkgs "${packageList[@]}"; then
    echo "Package installation failed. Please install the packages listed above manually and re-run this script."
    return 1
fi

echo "All missing packages installed successfully."
echo ""
return 0