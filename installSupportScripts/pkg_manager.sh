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
# Maps every logical name used in dependency_check.sh to its distro-specific
# package name(s). Every logical name is listed explicitly for every distro —
# nothing relies on the default passthrough case except genuinely unknown
# future names.
#
# A single logical name can resolve to MULTIPLE packages by returning a
# space-separated list (e.g. gvfs-mtp on apt/zypper needs several packages
# together) — install_pkgs splits on whitespace and treats each token as a
# separate package to check/install.

_resolve_pkg() {
    local logical="$1"
    case "$PKG_MANAGER" in
        pacman)
            case "$logical" in
                rsync)                  echo "rsync" ;;
                matugen)                echo "matugen" ;;
                waybar)                 echo "waybar" ;;
                rofi)                   echo "rofi" ;;
                swaync)                 echo "swaync" ;;
                nwg-displays)           echo "nwg-displays" ;;
                accurse)                echo "accurse" ;;
                rsvg-convert)           echo "librsvg" ;;
                xcursorgen)             echo "xorg-xcursorgen" ;;
                plasma-desktop)         echo "plasma-desktop" ;;
                kde-applications)       echo "kde-applications" ;;
                plasma-workspace)       echo "plasma-workspace" ;;
                cliphist)               echo "cliphist" ;;
                curl)                   echo "curl" ;;
                grim)                   echo "grim" ;;
                gvfs)                   echo "gvfs" ;;
                gvfs-mtp)               echo "gvfs-mtp" ;;
                hyprpolkitagent)        echo "hyprpolkitagent" ;;
                inxi)                   echo "inxi" ;;
                jq)                     echo "jq" ;;
                kitty)                  echo "kitty" ;;
                libspng)                echo "libspng" ;;
                nano)                   echo "nano" ;;
                network-manager-applet) echo "network-manager-applet" ;;
                pamixer)                echo "pamixer" ;;
                pavucontrol)            echo "pavucontrol" ;;
                playerctl)              echo "playerctl" ;;
                python-requests)        echo "python-requests" ;;
                python-pyquery)         echo "python-pyquery" ;;
                slurp)                  echo "slurp" ;;
                swappy)                 echo "swappy" ;;
                topgrade)               echo "topgrade" ;;
                wget)                   echo "wget" ;;
                wl-clipboard)           echo "wl-clipboard" ;;
                wlogout)                echo "wlogout" ;;
                xdg-user-dirs)          echo "xdg-user-dirs" ;;
                xdg-utils)              echo "xdg-utils" ;;
                yad)                    echo "yad" ;;
                *)                      echo "$logical" ;;
            esac ;;
        apt)
            case "$logical" in
                rsync)                  echo "rsync" ;;
                matugen)                echo "matugen" ;;
                waybar)                 echo "waybar" ;;
                rofi)                   echo "rofi" ;;
                swaync)                 echo "sway-notification-center" ;;
                nwg-displays)           echo "nwg-displays" ;;
                accurse)                echo "accurse" ;;
                rsvg-convert)           echo "librsvg2-bin" ;;
                xcursorgen)             echo "x11-apps" ;;
                plasma-desktop)         echo "kde-plasma-desktop" ;;
                kde-applications)       echo "kde-full" ;;
                plasma-workspace)       echo "plasma-workspace" ;;
                cliphist)               echo "cliphist" ;;   # not packaged — falls to go-install source build
                curl)                   echo "curl" ;;
                grim)                   echo "grim" ;;
                gvfs)                   echo "gvfs" ;;
                gvfs-mtp)               echo "gvfs-mtp gvfs-backends" ;;
                hyprpolkitagent)        echo "hyprpolkitagent" ;;   # not packaged — falls to source build
                inxi)                   echo "inxi" ;;
                jq)                     echo "jq" ;;
                kitty)                  echo "kitty" ;;
                libspng)                echo "libspng0" ;;
                nano)                   echo "nano" ;;
                network-manager-applet) echo "network-manager-gnome" ;;
                pamixer)                echo "pamixer" ;;
                pavucontrol)            echo "pavucontrol" ;;
                playerctl)              echo "playerctl" ;;
                python-requests)        echo "python3-requests" ;;
                python-pyquery)         echo "python3-pyquery" ;;
                slurp)                  echo "slurp" ;;
                swappy)                 echo "swappy" ;;
                topgrade)               echo "topgrade" ;;   # not packaged — falls to cargo source build
                wget)                   echo "wget" ;;
                wl-clipboard)           echo "wl-clipboard" ;;
                wlogout)                echo "wlogout" ;;
                xdg-user-dirs)          echo "xdg-user-dirs" ;;
                xdg-utils)              echo "xdg-utils" ;;
                yad)                    echo "yad" ;;
                *)                      echo "$logical" ;;
            esac ;;
        dnf)
            case "$logical" in
                rsync)                  echo "rsync" ;;
                matugen)                echo "matugen" ;;
                waybar)                 echo "waybar" ;;
                rofi)                   echo "rofi" ;;
                swaync)                 echo "SwayNotificationCenter" ;;   # COPR — see install_pkgs
                nwg-displays)           echo "nwg-displays" ;;
                accurse)                echo "accurse" ;;
                rsvg-convert)           echo "librsvg2-tools" ;;
                xcursorgen)             echo "xorg-x11-apps" ;;
                plasma-desktop)         echo "plasma-desktop" ;;
                kde-applications)       echo "kde-applications" ;;
                plasma-workspace)       echo "plasma-workspace" ;;
                cliphist)               echo "cliphist" ;;
                curl)                   echo "curl" ;;
                grim)                   echo "grim" ;;
                gvfs)                   echo "gvfs" ;;
                gvfs-mtp)               echo "gvfs-mtp" ;;
                hyprpolkitagent)        echo "hyprpolkitagent" ;;   # COPR — see install_pkgs
                inxi)                   echo "inxi" ;;
                jq)                     echo "jq" ;;
                kitty)                  echo "kitty" ;;
                libspng)                echo "libspng" ;;
                nano)                   echo "nano" ;;
                network-manager-applet) echo "network-manager-applet" ;;
                pamixer)                echo "pamixer" ;;
                pavucontrol)            echo "pavucontrol" ;;
                playerctl)              echo "playerctl" ;;
                python-requests)        echo "python3-requests" ;;
                python-pyquery)         echo "python3-pyquery" ;;
                slurp)                  echo "slurp" ;;
                swappy)                 echo "swappy" ;;
                topgrade)               echo "topgrade" ;;   # COPR — see install_pkgs
                wget)                   echo "wget" ;;
                wl-clipboard)           echo "wl-clipboard" ;;
                wlogout)                echo "wlogout" ;;
                xdg-user-dirs)          echo "xdg-user-dirs" ;;
                xdg-utils)              echo "xdg-utils" ;;
                yad)                    echo "yad" ;;
                *)                      echo "$logical" ;;
            esac ;;
        zypper)
            case "$logical" in
                rsync)                  echo "rsync" ;;
                matugen)                echo "matugen" ;;
                waybar)                 echo "waybar" ;;
                rofi)                   echo "rofi" ;;
                swaync)                 echo "SwayNotificationCenter" ;;
                nwg-displays)           echo "nwg-displays" ;;
                accurse)                echo "accurse" ;;
                rsvg-convert)           echo "rsvg-convert" ;;
                xcursorgen)             echo "xcursorgen" ;;
                plasma-desktop)         echo "patterns-kde-kde_plasma" ;;
                kde-applications)       echo "kde-applications" ;;
                plasma-workspace)       echo "plasma6-workspace" ;;
                cliphist)               echo "cliphist" ;;
                curl)                   echo "curl" ;;
                grim)                   echo "grim" ;;
                gvfs)                   echo "gvfs" ;;
                gvfs-mtp)               echo "gvfs-backend mtpfs mtp-tools libmtp-runtime" ;;
                hyprpolkitagent)        echo "hyprpolkitagent" ;;
                inxi)                   echo "inxi" ;;
                jq)                     echo "jq" ;;
                kitty)                  echo "kitty" ;;
                libspng)                echo "libspng0" ;;
                nano)                   echo "nano" ;;
                network-manager-applet) echo "NetworkManager-applet" ;;
                pamixer)                echo "pamixer" ;;
                pavucontrol)            echo "pavucontrol" ;;
                playerctl)              echo "playerctl" ;;
                python-requests)        echo "python3-requests" ;;
                python-pyquery)         echo "python3-pyquery" ;;
                slurp)                  echo "slurp" ;;
                swappy)                 echo "swappy" ;;
                topgrade)               echo "topgrade" ;;   # not in default Tumbleweed repos — falls to cargo source build
                wget)                   echo "wget" ;;
                wl-clipboard)           echo "wl-clipboard" ;;
                wlogout)                echo "wlogout" ;;
                xdg-user-dirs)          echo "xdg-user-dirs" ;;
                xdg-utils)              echo "xdg-utils" ;;
                yad)                    echo "yad" ;;
                *)                      echo "$logical" ;;
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
#   matugen         — cargo install
#   awww            — git clone + cargo build (not on crates.io)
#   nwg-displays    — git clone + upstream's own install.sh (repo-packaged on
#                     Arch already; this is the non-Arch fallback)
#   accurse         — pip install (on PyPI; always installed this way
#                     regardless of distro, per upstream's own instructions)
#   cliphist        — go install (not packaged for Debian/Ubuntu)
#   hyprpolkitagent — git clone + upstream's own build.sh (UNVERIFIED —
#                     depends on hyprtoolkit's own build chain; not packaged
#                     for Debian/Ubuntu)
#   topgrade        — cargo install (no official package on Debian/Ubuntu or
#                     default openSUSE Tumbleweed repos; Arch uses AUR and
#                     Fedora uses COPR instead, both via their normal paths)

_SOURCE_BUILDABLE=("matugen" "awww" "nwg-displays" "accurse" "cliphist" "hyprpolkitagent" "topgrade")

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

_ensure_go() {
    if command -v go &>/dev/null; then return 0; fi
    echo "Go is required but is not installed. Installing..."
    case "$PKG_MANAGER" in
        apt)    sudo apt-get install -y golang-go ;;
        dnf)    sudo dnf install -y golang ;;
        zypper) sudo zypper install -y go ;;
        *)      echo "Please install Go manually and re-run this script."; return 1 ;;
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
            cliphist)
                _ensure_go || return 1
                echo "Installing cliphist via go install (go.senan.xyz/cliphist)..."
                if ! go install go.senan.xyz/cliphist@latest; then
                    echo "Failed to install cliphist via go. Please install it manually and re-run this script."
                    return 1
                fi
                local gobin
                gobin="$(go env GOPATH 2>/dev/null)/bin"
                if [ -x "$gobin/cliphist" ] && ! command -v cliphist &>/dev/null; then
                    sudo install -m755 "$gobin/cliphist" /usr/local/bin/cliphist
                fi
                echo "cliphist installed successfully."
                ;;
            hyprpolkitagent)
                # UNVERIFIED build path — hyprpolkitagent depends on hyprtoolkit
                # (pulled in as a submodule) and its own dependency chain. If
                # build.sh fails, check the repo's flake.nix/CMakeLists.txt for
                # the full list of build dependencies and install them manually.
                echo "Building hyprpolkitagent from source (github.com/hyprwm/hyprpolkitagent)..."
                if ! command -v git &>/dev/null; then
                    echo "git is required to build hyprpolkitagent but is not installed."
                    return 1
                fi
                local tmp
                tmp="$(mktemp -d)"
                git clone --recursive https://github.com/hyprwm/hyprpolkitagent "$tmp/hyprpolkitagent" || { echo "Failed to clone hyprpolkitagent."; rm -rf "$tmp"; return 1; }
                if ! (cd "$tmp/hyprpolkitagent" && chmod +x build.sh && ./build.sh); then
                    echo "Failed to build hyprpolkitagent. Please build it manually following the repo's own instructions."
                    rm -rf "$tmp"
                    return 1
                fi
                local bin
                bin="$(find "$tmp/hyprpolkitagent" -maxdepth 4 -type f -name hyprpolkitagent -perm -u+x | head -n1)"
                if [ -n "$bin" ]; then
                    sudo install -m755 "$bin" /usr/local/bin/hyprpolkitagent
                    echo "hyprpolkitagent installed to /usr/local/bin."
                else
                    echo "Build finished but the hyprpolkitagent binary wasn't found automatically. Check the repo's build output and install it manually."
                fi
                rm -rf "$tmp"
                ;;
            topgrade)
                _ensure_cargo || return 1
                echo "Building topgrade from source (cargo install topgrade)..."
                if ! cargo install topgrade; then
                    echo "Failed to build topgrade. Please install it manually and re-run this script."
                    return 1
                fi
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
# A logical name may resolve to multiple real packages (space-separated);
# all of them are checked and installed together.

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

        # swaync isn't in Fedora's official repos — only via the maintainer's
        # own COPR. Enable it before the repo check below.
        if [ "$pkg" = "swaync" ] && [ "$PKG_MANAGER" = "dnf" ]; then
            if ! dnf copr list --enabled 2>/dev/null | grep -qi "erikreider/SwayNotificationCenter"; then
                echo "Enabling COPR repo for swaync (erikreider/SwayNotificationCenter)..."
                sudo dnf copr enable -y erikreider/SwayNotificationCenter || {
                    echo "Failed to enable COPR repo for swaync. Please enable it manually and re-run:"
                    echo "  sudo dnf copr enable erikreider/SwayNotificationCenter"
                    return 1
                }
            fi
        fi

        # hyprpolkitagent isn't in Fedora's official repos either — COPR only.
        if [ "$pkg" = "hyprpolkitagent" ] && [ "$PKG_MANAGER" = "dnf" ]; then
            if ! dnf copr list --enabled 2>/dev/null | grep -qi "solopasha/hyprland"; then
                echo "Enabling COPR repo for hyprpolkitagent (solopasha/hyprland)..."
                sudo dnf copr enable -y solopasha/hyprland || {
                    echo "Failed to enable COPR repo for hyprpolkitagent. Please enable it manually and re-run:"
                    echo "  sudo dnf copr enable solopasha/hyprland"
                    return 1
                }
            fi
        fi

        # topgrade isn't in Fedora's official repos either — COPR only.
        if [ "$pkg" = "topgrade" ] && [ "$PKG_MANAGER" = "dnf" ]; then
            if ! dnf copr list --enabled 2>/dev/null | grep -qi "lilay/topgrade"; then
                echo "Enabling COPR repo for topgrade (lilay/topgrade)..."
                sudo dnf copr enable -y lilay/topgrade || {
                    echo "Failed to enable COPR repo for topgrade. Please enable it manually and re-run:"
                    echo "  sudo dnf copr enable lilay/topgrade"
                    return 1
                }
            fi
        fi

        local resolved
        resolved="$(_resolve_pkg "$pkg")"

        # A logical name can resolve to multiple space-separated packages.
        # All of them must be found in official repos for this to count as
        # "in repo" — otherwise the whole logical package falls through to
        # the AUR/source-build path instead of installing a partial set.
        local resolvedTokens=()
        read -ra resolvedTokens <<< "$resolved"

        local allInRepo=true
        for tok in "${resolvedTokens[@]}"; do
            case "$PKG_MANAGER" in
                pacman) pacman -Si "$tok" &>/dev/null || allInRepo=false ;;
                apt)    apt-cache show "$tok" &>/dev/null || allInRepo=false ;;
                dnf)    dnf info "$tok" &>/dev/null || allInRepo=false ;;
                zypper) zypper info "$tok" &>/dev/null || allInRepo=false ;;
            esac
        done

        if [ "$allInRepo" = true ]; then
            repoPkgs+=("${resolvedTokens[@]}")
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