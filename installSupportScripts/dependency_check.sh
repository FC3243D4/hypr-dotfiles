#!/usr/bin/env bash
# dependency_check.sh
# Checks for required dependencies and installs any that are missing.
# Meant to be SOURCED from install.sh (not executed) so that
# UseXrandr / UseWayland are visible to the caller.
#
# Returns 0 on success, 1 on failure (caller should check $? and stop).

source "$SUPPORT/pkg_manager.sh" || return 1

packageList=()

# Each entry is "check_command|package_name". check_command is eval'd; if it
# fails, package_name is printed and added to packageList.
_check_dep() {
    local check="$1" pkgname="$2"
    if ! eval "$check" &>/dev/null; then
        echo "$pkgname"
        packageList+=("$pkgname")
    fi
}

_check_deps() {
    local entry check pkgname
    for entry in "$@"; do
        check="${entry%%|*}"
        pkgname="${entry#*|}"
        _check_dep "$check" "$pkgname"
    done
}

echo "Checking dependencies..."

coreDeps=(
    "command -v rsync|rsync"
    "matugen --version|matugen"
    "waybar --version|waybar"
    "command -v rofi|rofi"
)
_check_deps "${coreDeps[@]}"

if ! command -v openrgb &>/dev/null; then
    echo "openrgb is not installed. You will not have the wallpaper's dominant color applied to your devices. Please install openrgb if you want this feature."
    echo ""
fi

# --- General utilities (JaKooLit base dependency list + extras) ---
generalDeps=(
    "command -v cliphist|cliphist"
    "command -v curl|curl"
    "command -v grim|grim"
    "command -v gvfsd|gvfs"
    "command -v gvfsd-mtp|gvfs-mtp"
    "command -v hyprpolkitagent|hyprpolkitagent"
    "command -v inxi|inxi"
    "command -v jq|jq"
    "command -v kitty|kitty"
    "command -v nano|nano"
    "command -v nm-applet|network-manager-applet"
    "command -v pamixer|pamixer"
    "command -v pavucontrol|pavucontrol"
    "command -v playerctl|playerctl"
    "python3 -c 'import requests'|python-requests"
    "python3 -c 'import pyquery'|python-pyquery"
    "command -v slurp|slurp"
    "command -v swappy|swappy"
    "command -v wget|wget"
    "command -v wl-copy|wl-clipboard"
    "command -v wlogout|wlogout"
    "command -v xdg-user-dirs-update|xdg-user-dirs"
    "command -v xdg-open|xdg-utils"
    "command -v yad|yad"
    "command -v topgrade|topgrade"
    "command -v lspci|pciutils"
    "pkg-config --exists spng|libspng"
)
_check_deps "${generalDeps[@]}"

# --- Display management (nwg-displays) ---
displayDeps=(
    "command -v nwg-displays|nwg-displays"
)
_check_deps "${displayDeps[@]}"

# --- Cursor theme compiler (accurse) ---
cursorDeps=(
    "command -v accurse|accurse"
    "command -v rsvg-convert|rsvg-convert"
    "command -v xcursorgen|xcursorgen"
)
_check_deps "${cursorDeps[@]}"

# --- KDE section ---
echo "Checking KDE dependencies..."
kdeDeps=(
    "command -v plasmashell|plasma-desktop"
    "command -v dolphin|kde-applications"
    "command -v plasma-apply-colorscheme|plasma-workspace"
)
_check_deps "${kdeDeps[@]}"

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

if ! command -v kwriteconfig6 &>/dev/null; then
    echo ""
    echo "Warning: kwriteconfig6 still not found after installing KDE packages."
    echo "This is unexpected (it's normally pulled in as a dependency of plasma-workspace)."
    echo "Please check your distro's KConfig package manually — matugen's KDE color-scheme patcher needs it."
fi

echo "All missing packages installed successfully."
echo ""
return 0