#!/usr/bin/env bash
# dependency_check.sh
# Checks for required dependencies and installs any that are missing.
# Meant to be SOURCED from install.sh (not executed) so that
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
if ! command -v rofi &>/dev/null; then
    echo "rofi"
    packageList+=("rofi")
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

if ! command -v plasma-apply-colorscheme &>/dev/null; then
    echo "plasma-apply-colorscheme"
    packageList+=("plasma-workspace")
fi

if (( ${#packageList[@]} == 0 )); then
    echo "All dependencies are already installed."
    return 0
fi

if ! command -v cliphist &>/dev/null; then
    echo "cliphist"
    packageList+=("cliphist")
fi

if ! command -v curl &>/dev/null; then
    echo "curl"
    packageList+=("curl")
fi

if ! command -v grim &>/dev/null; then
    echo "grim"
    packageList+=("grim")
fi

if ! command -v gvfsd &>/dev/null; then
    echo "gvfs"
    packageList+=("gvfs")
fi

if ! command -v gvfsd-mtp &>/dev/null; then
    echo "gvfs-mtp"
    packageList+=("gvfs-mtp")
fi

if ! command -v hyprpolkitagent &>/dev/null; then
    echo "hyprpolkitagent"
    packageList+=("hyprpolkitagent")
fi

if ! command -v inxi &>/dev/null; then
    echo "inxi"
    packageList+=("inxi")
fi

if ! command -v jq &>/dev/null; then
    echo "jq"
    packageList+=("jq")
fi

if ! command -v kitty &>/dev/null; then
    echo "kitty"
    packageList+=("kitty")
fi

if ! command -v nano &>/dev/null; then
    echo "nano"
    packageList+=("nano")
fi

if ! command -v nm-applet &>/dev/null; then
    echo "network-manager-applet"
    packageList+=("network-manager-applet")
fi

if ! command -v pamixer &>/dev/null; then
    echo "pamixer"
    packageList+=("pamixer")
fi

if ! command -v pavucontrol &>/dev/null; then
    echo "pavucontrol"
    packageList+=("pavucontrol")
fi

if ! command -v playerctl &>/dev/null; then
    echo "playerctl"
    packageList+=("playerctl")
fi

if ! python3 -c "import requests" &>/dev/null; then
    echo "python-requests"
    packageList+=("python-requests")
fi

if ! python3 -c "import pyquery" &>/dev/null; then
    echo "python-pyquery"
    packageList+=("python-pyquery")
fi

if ! command -v slurp &>/dev/null; then
    echo "slurp"
    packageList+=("slurp")
fi

if ! command -v swappy &>/dev/null; then
    echo "swappy"
    packageList+=("swappy")
fi

if ! command -v wget &>/dev/null; then
    echo "wget"
    packageList+=("wget")
fi

if ! command -v wl-copy &>/dev/null; then
    echo "wl-clipboard"
    packageList+=("wl-clipboard")
fi

if ! command -v wlogout &>/dev/null; then
    echo "wlogout"
    packageList+=("wlogout")
fi

if ! command -v xdg-user-dirs-update &>/dev/null; then
    echo "xdg-user-dirs"
    packageList+=("xdg-user-dirs")
fi

if ! command -v xdg-open &>/dev/null; then
    echo "xdg-utils"
    packageList+=("xdg-utils")
fi

if ! command -v yad &>/dev/null; then
    echo "yad"
    packageList+=("yad")
fi

if ! command -v topgrade &>/dev/null; then
    echo "topgrade"
    packageList+=("topgrade")
fi

# libspng has no standalone CLI binary to check for — it's a linked library,
# not a standalone tool. Checked via pkg-config instead.
if ! pkg-config --exists spng &>/dev/null; then
    echo "libspng"
    packageList+=("libspng")
fi

echo "The following packages are missing and will be installed:"
printf '  %s\n' "${packageList[@]}"
echo ""

sync_repos
if ! install_pkgs "${packageList[@]}"; then
    echo "Package installation failed. Please install the packages listed above manually and re-run this script."
    return 1
fi

if ! command -v kwriteconfig6 &>/dev/null; then
    echo ""
    echo "Warning: kwriteconfig6 still not found after installing KDE packages."
    echo "This is unexpected (it's normally pulled in as a dependency of plasma-workspace)."
    echo "Please check your distro's KConfig package manually — matugen's KDE color-scheme patcher needs it."
fi

echo "All missing packages installed successfully."
echo ""
return 0