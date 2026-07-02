# hypr-dotfiles

Hyprland dotfiles for a hybrid KDE Plasma / Hyprland setup, dual-booted alongside Windows. Built on top of [JaKooLit's Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) as a base, then reworked and extended for a KDE-integrated workflow — matugen-driven theming instead of wallust, KDE color-scheme/notification patching, a custom dependency-resolution installer, and a few tools of my own.

## What's in here

- **Hyprland** config (`hypr/`)
- **Waybar** config (`waybar/`)
- **Rofi** config (`rofi/`)
- **SwayNotificationCenter** config (`swaync/`)
- **matugen** config and templates (`matugen/`) — generates the accent-color theming from your wallpaper and pushes it out to Waybar, Hyprland, Kitty, Rofi, GTK, KDE color schemes, and a few per-app patchers
- `install.sh` — dependency check + install, config sync, monitor setup, cursor theme build, and companion tool installation
- `installSupportScripts/` — package-manager abstraction (`pkg_manager.sh`) and dependency checking (`dependency_check.sh`) used by `install.sh`

## Credit

The Hyprland configuration in this repo started from [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) and has been substantially modified since — theming pipeline, KDE integration, and install tooling are all custom, but the base config structure, a lot of the original keybind/window-rule scaffolding, and the base utility dependency list trace back to that project. Go check it out if you want the unmodified, Arch-focused original.

## Requirements

- A KDE Plasma / Hyprland hybrid setup (dual `.desktop` session, or a distro that ships both)
- `git`
- `sudo` access (the installer installs system packages)

Everything else is checked and installed automatically by `install.sh`. See [Dependencies](#dependencies) below for the full list and what each one is for.

## Installation

```sh
git clone https://github.com/FC3243D4/hypr-dotfiles
cd hypr-dotfiles
chmod +x install.sh
./install.sh
```

`install.sh` runs through the following steps, in order:

1. **Dependency check** — detects your package manager (`pacman`, `apt`, `dnf`, or `zypper`) and installs anything missing. `openrgb` is checked but optional — you'll get a warning, not a failure, if it's absent.
2. **Config sync** — `rsync`'s `hypr/`, `matugen/`, `rofi/`, `waybar/`, and `swaync/` into `~/.config/`. This is additive (no `--delete`), so nothing you've added locally to those folders gets removed on a re-run. Anything already present at those paths that wasn't put there by this script gets backed up once, to `<name>.bak`, before the first sync.
3. **Monitor config** — if you're in an active Hyprland session, launches `nwg-displays` so you can arrange your outputs and generate `~/.config/hypr/monitors.conf`. If you run the installer from KDE (or before your first Hyprland login), this step is skipped with instructions to run it manually later — `nwg-displays` only supports sway/Hyprland/Niri and can't run under Plasma.
4. **Cursor theme** — clones [accurse](https://github.com/ATM-Jahid/accurse), patches its bundled Breeze theme (recolored, extended size set), compiles it, and installs the result to `~/.local/share/icons/AC-Breeze`.
5. **Wallpaper-changer** — clones (or updates) [FC3243D4/Wallpaper-changer](https://github.com/FC3243D4/Wallpaper-changer) as a sibling directory next to this repo and runs its own installer.

Re-running `install.sh` is safe — it'll pick up dependency and config changes without clobbering local edits or reinstalling things that are already present.

## Dependencies

### Theming / desktop integration

| Package | Purpose |
|---|---|
| `rsync` | Config syncing during install |
| `matugen` | Wallpaper-based accent color extraction and theme generation |
| `waybar` | Status bar |
| `rofi` | Application launcher / menus |
| `swaync` | Notification daemon and control center (installed via COPR on Fedora) |
| `nwg-displays` | GUI monitor/workspace configuration for Hyprland |
| `accurse` | Cursor theme compiler (hyprcursor + XCursor) |
| `rsvg-convert`, `xcursorgen` | Runtime dependencies of accurse |
| KDE application suite | Full KDE app set for the hybrid session (Dolphin, Konsole, etc.) — also transitively provides `kwriteconfig6`/`kreadconfig6`, used by matugen's KDE color-scheme patcher |
| `plasma-apply-colorscheme` | Applies generated KDE color schemes |
| `hyprpolkitagent` | Polkit authentication agent for the Hyprland session (installed via COPR on Fedora; built from source on Debian/Ubuntu) |
| `openrgb` (optional) | Syncs the wallpaper's dominant color to RGB peripherals |

### General utilities

Base set carried over from JaKooLit's Hyprland-Dots: `cliphist`, `curl`, `grim`, `gvfs`, `gvfs-mtp`, `inxi`, `jq`, `kitty`, `libspng`, `nano`, `network-manager-applet`, `pamixer`, `pavucontrol`, `playerctl`, `python-requests`, `python-pyquery`, `slurp`, `swappy`, `wget`, `wl-clipboard`, `wlogout`, `xdg-user-dirs`, `xdg-utils`, `yad`.

`cliphist` is installed via `go install` on Debian/Ubuntu (not packaged there). `gvfs-mtp` pulls in extra companion packages on Debian/Ubuntu (`gvfs-backends`) and openSUSE (`gvfs-backend`, `mtpfs`, `mtp-tools`, `libmtp-runtime`) since MTP support is split across several packages on those distros.

Package names are resolved per-distro in `installSupportScripts/pkg_manager.sh`. This is primarily developed and tested on **CachyOS (Arch-based)** — the Debian/Fedora/openSUSE mappings are provided for portability and are verified against upstream package listings, with one exception: `hyprpolkitagent`'s source-build fallback for Debian/Ubuntu (it's not packaged there) is untested and may need manual dependency installation if `build.sh` fails.

## Gamemode

`hypr/scripts/gamemode.sh` (bound to a keybind in the Hyprland config) toggles a "gamemode" state that:

- Stops `docker`/`ollama` systemd units to free up resources — only for units that actually exist on the system, so this is safe to use even if you don't have Docker or Ollama installed
- Suppresses notifications via `swaync` (Hyprland session) or KDE's Do Not Disturb system (Plasma session), detected via `$XDG_CURRENT_DESKTOP`
- Reloads Hyprland and toggles `hypridle`

Running it again reverses all of the above.

## Notes

- This is a personal ricing setup, not a general-purpose installer — expect some paths and assumptions (like the Wallpaper-changer clone location, or the exact KDE apps installed) to be specific to how I use this. Feel free to fork and adjust.
- The theming pipeline uses `.base` backup files internally to avoid config state accumulating across repeated runs.