#!/usr/bin/env bash
# pkg_manager.sh
# Detects the package manager and provides install/sync abstractions.
# Meant to be SOURCED by dependency_check.sh.
#
# Exports:
#   PKG_MANAGER   — detected package manager (pacman, apt, dnf, zypper)
#   sync_repos    — refresh package database
#   install_pkgs  — install a list of logical package names

# ─── Detect package manager ──────────────────────────────────────────────────

if command -v pacman &>/dev/null;  then PKG_MANAGER="pacman"
elif command -v apt &>/dev/null;   then PKG_MANAGER="apt"
elif command -v dnf &>/dev/null;   then PKG_MANAGER="dnf"
elif command -v zypper &>/dev/null; then PKG_MANAGER="zypper"
else
    echo "Unsupported package manager. Please install dependencies manually."
    return 1
fi

# ─── Package name map ────────────────────────────────────────────────────────
# Maps logical names used in dependency_check.sh to the distro-specific
# package name. Add entries here when names differ.

_resolve_pkg() {
    local logical="$1"
    case "$PKG_MANAGER" in
        pacman)
            case "$logical" in
                rsync)            echo "rsync" ;;
                rofi)             echo "rofi" ;;
                swaync)           echo "swaync" ;;
                kconfig)          echo "kconfig" ;;
                plasma-desktop)   echo "plasma-desktop" ;;
                plasma-workspace) echo "plasma-workspace" ;;
                rsvg-convert)     echo "librsvg" ;;
                xcursorgen)       echo "xorg-xcursorgen" ;;
                *)                echo "$logical" ;;
            esac ;;
        apt)
            case "$logical" in
                rsync)            echo "rsync" ;;
                rofi)             echo "rofi" ;;
                swaync)           echo "swaync" ;;   # UNVERIFIED — check manually, may not be in Debian stable/Ubuntu
                kconfig)          echo "libkf6config-bin" ;;
                plasma-desktop)   echo "kde-plasma-desktop" ;;
                plasma-workspace) echo "plasma-workspace" ;;
                rsvg-convert)     echo "librsvg2-bin" ;;
                xcursorgen)       echo "x11-apps" ;;   # UNVERIFIED — check manually
                *)                echo "$logical" ;;
            esac ;;
        dnf)
            case "$logical" in
                rsync)            echo "rsync" ;;
                rofi)             echo "rofi" ;;
                swaync)           echo "swaync" ;;
                kconfig)          echo "kf6-kconfig" ;;
                plasma-desktop)   echo "plasma-desktop" ;;
                plasma-workspace) echo "plasma-workspace" ;;
                rsvg-convert)     echo "librsvg2-tools" ;;
                xcursorgen)       echo "xorg-x11-apps" ;;  # UNVERIFIED — check manually
                *)                echo "$logical" ;;
            esac ;;
        zypper)
            case "$logical" in
                rsync)            echo "rsync" ;;
                rofi)             echo "rofi" ;;
                swaync)           echo "swaync" ;;   # UNVERIFIED — check manually
                kconfig)          echo "kconfig6" ;;   # UNVERIFIED — check manually
                plasma-desktop)   echo "patterns-kde-kde_plasma" ;;
                plasma-workspace) echo "plasma6-workspace" ;;
                rsvg-convert)     echo "rsvg-convert" ;;   # UNVERIFIED — check manually
                xcursorgen)       echo "xorg-x11" ;;       # UNVERIFIED — check manually
                *)                echo "$logical" ;;
            esac ;;
    esac
}

# ─── Sync repos ──────────────────────────────────────────────────────────────

sync_repos() {
    echo "Syncing package databases..."
    case "$PKG_MANAGER" in
        pacman) sudo pacman -Sy ;;
        apt)    sudo apt-get update ;;
        dnf)    sudo dnf check-update || true ;;  # dnf returns 100 when updates are available, not an error
        zypper) sudo zypper refresh ;;
    esac
}

# ─── Full KDE application suite (group/pattern install, not a flat package) ──
# Handled separately from install_pkgs because "kde-applications" is a pacman
# group, a dnf comps group, a zypper pattern, and only a real single package
# on Debian/Ubuntu (kde-full). None of that fits the flat-package assumption
# the rest of install_pkgs relies on.

_install_kde_apps() {
    echo "Installing full KDE application suite (this is a large download)..."
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -S --needed --noconfirm kde-applications
            ;;
        apt)
            sudo apt-get install -y kde-full
            ;;
        dnf)
            sudo dnf group install -y "KDE Plasma Workspaces"
            ;;
        zypper)
            sudo zypper install -y -t pattern kde_plasma
            ;;
    esac
}

# ─── Build-from-source fallback ──────────────────────────────────────────────
# Packages that aren't reliably available via any distro's official repos
# (and, for accurse, aren't meant to be — upstream's own install method is pip).
#
#   matugen      — cargo install
#   awww         — git clone + cargo build (not on crates.io)
#   nwg-displays — git clone + upstream's own install.sh (repo-packaged on
#                  Arch already; this is the non-Arch fallback)
#   accurse      — pip install (on PyPI; always installed this way regardless
#                  of distro, per upstream's own instructions)

_SOURCE_BUILDABLE=("matugen" "awww" "nwg-displays" "accurse")

_is_source_buildable() {
    local pkg="$1"
    for p in "${_SOURCE_BUILDABLE[@]}"; do
        [ "$p" = "$pkg" ] && return 0
    done
    return 1
}

_ensure_cargo() {
    if command -v cargo &>/dev/null; then return 0; fi
    echo "cargo is required but is not installed. Installing Rust toolchain..."
    case "$PKG_MANAGER" in
        apt)    sudo apt-get install -y cargo ;;
        dnf)    sudo dnf install -y cargo ;;
        zypper) sudo zypper install -y cargo ;;
        *)      echo "Please install cargo manually and re-run this script."; return 1 ;;
    esac
}

_install_from_source() {
    local pkgs=("$@")

    for pkg in "${pkgs[@]}"; do
        case "$pkg" in
            matugen)
                _ensure_cargo || return 1
                echo "Building matugen from source (cargo install matugen)..."
                if ! cargo install matugen; then
                    echo "Failed to build matugen. Please install it manually and re-run this script."
                    return 1
                fi
                ;;
            awww)
                # awww is not on crates.io — must be cloned and built from source.
                # Both the awww and awww-daemon binaries are required.
                _ensure_cargo || return 1
                echo "Building awww from source (codeberg.org/LGFae/awww)..."
                if ! command -v git &>/dev/null; then
                    echo "git is required to build awww but is not installed."
                    return 1
                fi
                local tmp
                tmp="$(mktemp -d)"
                git clone https://codeberg.org/LGFae/awww "$tmp/awww" || { echo "Failed to clone awww."; rm -rf "$tmp"; return 1; }
                (cd "$tmp/awww" && cargo build --release) || { echo "Failed to build awww."; rm -rf "$tmp"; return 1; }
                sudo install -m755 "$tmp/awww/target/release/awww" /usr/local/bin/awww
                sudo install -m755 "$tmp/awww/target/release/awww-daemon" /usr/local/bin/awww-daemon
                rm -rf "$tmp"
                echo "awww installed successfully."
                ;;
            nwg-displays)
                echo "Building nwg-displays from source (github.com/nwg-piotr/nwg-displays)..."
                if ! command -v git &>/dev/null; then
                    echo "git is required to build nwg-displays but is not installed."
                    return 1
                fi
                if ! python3 -c "import build, installer" &>/dev/null; then
                    echo "Installing Python build backend (build, installer, wheel)..."
                    pip install --break-system-packages --quiet build installer wheel || {
                        echo "Failed to install Python build tools. Please install 'python-build', 'python-installer', and 'python-wheel' (names vary by distro) manually."
                        return 1
                    }
                fi
                local tmp
                tmp="$(mktemp -d)"
                git clone https://github.com/nwg-piotr/nwg-displays "$tmp/nwg-displays" || { echo "Failed to clone nwg-displays."; rm -rf "$tmp"; return 1; }
                (cd "$tmp/nwg-displays" && sudo ./install.sh) || { echo "Failed to build/install nwg-displays."; rm -rf "$tmp"; return 1; }
                rm -rf "$tmp"
                echo "nwg-displays installed successfully."
                ;;
            accurse)
                echo "Installing accurse via pip..."
                local pipcmd=""
                command -v pip3 &>/dev/null && pipcmd="pip3"
                [ -z "$pipcmd" ] && command -v pip &>/dev/null && pipcmd="pip"
                if [ -z "$pipcmd" ]; then
                    echo "pip is required to install accurse but is not installed. Please install python-pip and re-run this script."
                    return 1
                fi
                if ! "$pipcmd" install --break-system-packages accurse; then
                    echo "Failed to install accurse via pip. Please install it manually (pip install accurse) and re-run this script."
                    return 1
                fi
                echo "accurse installed successfully. Note: accurse also needs 'rsvg-convert' and 'xcursorgen' on PATH (see the rsvg-convert / xcursorgen dependency checks)."
                ;;
            *)
                echo "No source build method available for $pkg. Please install it manually."
                return 1
                ;;
        esac
    done
}

# ─── Install packages ─────────────────────────────────────────────────────────
# Usage: install_pkgs <logical_name> [<logical_name> ...]
# Handles repo vs AUR split on Arch; on other distros installs everything
# via the system package manager, with a build-from-source fallback.

install_pkgs() {
    local logicalPkgs=("$@")
    local repoPkgs=()
    local aurPkgs=()
    local sourcePkgs=()

    for pkg in "${logicalPkgs[@]}"; do
        # Group/pattern installs that don't fit the flat-package model.
        if [ "$pkg" = "kde-applications" ]; then
            _install_kde_apps || return 1
            continue
        fi

        # accurse is always installed via pip regardless of distro — it's on
        # PyPI and that's upstream's own recommended install method.
        if [ "$pkg" = "accurse" ]; then
            sourcePkgs+=("accurse")
            continue
        fi

        local resolved
        resolved="$(_resolve_pkg "$pkg")"

        # Check if the package exists in official repos
        local inRepo=false
        case "$PKG_MANAGER" in
            pacman) pacman -Si "$resolved" &>/dev/null && inRepo=true ;;
            apt)    apt-cache show "$resolved" &>/dev/null && inRepo=true ;;
            dnf)    dnf info "$resolved" &>/dev/null && inRepo=true ;;
            zypper) zypper info "$resolved" &>/dev/null && inRepo=true ;;
        esac

        if [ "$inRepo" = true ]; then
            repoPkgs+=("$resolved")
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            # Not in official repos on Arch — try AUR
            aurPkgs+=("$pkg")
        elif _is_source_buildable "$pkg"; then
            # Not in official repos on non-Arch — build/install from source
            sourcePkgs+=("$pkg")
        else
            echo "Package '$pkg' not found in official repos and no fallback is available. Please install it manually."
            return 1
        fi
    done

    # Install repo packages
    if (( ${#repoPkgs[@]} != 0 )); then
        echo "Installing from official repos: ${repoPkgs[*]}"
        case "$PKG_MANAGER" in
            pacman) sudo pacman -S --needed --noconfirm "${repoPkgs[@]}" ;;
            apt)    sudo apt-get install -y "${repoPkgs[@]}" ;;
            dnf)    sudo dnf install -y "${repoPkgs[@]}" ;;
            zypper) sudo zypper install -y "${repoPkgs[@]}" ;;
        esac
    fi

    # Install AUR packages (Arch only)
    if (( ${#aurPkgs[@]} != 0 )); then
        echo "Installing from AUR: ${aurPkgs[*]}"
        if command -v paru &>/dev/null; then
            paru -S --needed --noconfirm "${aurPkgs[@]}"
        elif command -v yay &>/dev/null; then
            yay -S --needed --noconfirm "${aurPkgs[@]}"
        else
            echo "No AUR helper (paru/yay) found. The following packages were not found in the official repos:"
            printf '  %s\n' "${aurPkgs[@]}"
            echo "Please install paru or yay first, then re-run this script."
            return 1
        fi
    fi

    # Build from source as last resort
    if (( ${#sourcePkgs[@]} != 0 )); then
        _install_from_source "${sourcePkgs[@]}" || return 1
    fi
}