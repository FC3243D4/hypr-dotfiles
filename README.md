# hypr-dotfiles

Hyprland dotfiles for a hybrid KDE Plasma / Hyprland setup, dual-booted alongside Windows. Built on top of [JaKooLit's Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) as a base, then reworked and extended for a KDE-integrated workflow — matugen-driven theming instead of wallust, KDE color-scheme/notification patching, a custom dependency-resolution installer, and a few tools of my own.

## What's in here

- **Hyprland** config (`hypr/`)
- **Waybar** config (`waybar/`)
- **Rofi** config (`rofi/`)
- **SwayNotificationCenter** config (`swaync/`)
- **wlogout** config (`wlogout/`)
- **matugen** config and templates (`matugen/`) — generates the accent-color theming from your wallpaper and pushes it out to Waybar, Hyprland, Kitty, Rofi, GTK, KDE color schemes, Spicetify, Vesktop (Midnight Discord), VS Code, and a few other per-app patchers
- **Icon patchers** — recolor the icon set (a mix of Tabler Icons and custom icons) shipped in the [Wallpaper-changer](https://github.com/FC3243D4/Wallpaper-changer) repo to match the current accent color and push them out per-app (VS Code, Ferdium service recipes, browsers, Discord, etc.) — see [Icons](#icons) below
- `install.sh` — dependency check + install, config sync, GPU-aware env toggling, Hyprland/Waybar preferences, monitor setup, cursor theme build, Spicetify/Vesktop theming setup, and companion tool installation
- `installSupportScripts/` — package-manager abstraction (`pkg_manager.sh`) and dependency checking (`dependency_check.sh`) used by `install.sh`

## Credit

The Hyprland configuration in this repo started from [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) and has been substantially modified since — theming pipeline, KDE integration, and install tooling are all custom, but the base config structure, a lot of the original keybind/window-rule scaffolding, and the base utility dependency list trace back to that project. Go check it out if you want the unmodified, Arch-focused original.

Most of the matugen templates themselves (Waybar, Hyprland/hyprlock, Kitty, Rofi, wlogout, swaync, Vesktop's Midnight Discord theme, VS Code) are adapted from [InioX/matugen-themes](https://github.com/InioX/matugen-themes), migrated over from an earlier hand-rolled template set. Go check that repo out too if you want more matugen-driven app themes than what's wired up here.

## Requirements

- A KDE Plasma / Hyprland hybrid setup
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
2. **Config sync** — `rsync`'s `hypr/`, `matugen/`, `rofi/`, `waybar/`, `swaync/`, and `wlogout/` into `~/.config/`. This is additive (no `--delete`), so nothing you've added locally to those folders gets removed on a re-run. Anything already present at those paths that wasn't put there by this script gets backed up once, to `<name>.bak`, before the first sync.
3. **GPU env toggle** — detects whether an NVIDIA GPU is present via `lspci` and comments/uncomments the NVIDIA block in `~/.config/hypr/ENVariables.lua` accordingly. Idempotent — safe to re-run on the same or different hardware.
4. **Hyprland user preferences** — interactively sets a handful of `hl.env(...)` values in `01-UserDefaults.lua`: your primary display (picked from every output `xrandr` reports as connected), number of persistent workspaces, default Hyprland layout (`master`/`dwindle`/`scrolling`), and default editor (detected from whatever's actually installed among `nano`/`vim`/`nvim`/`code`/`micro`/`emacs`/`hx`/`kate`/`gedit`, defaulting to `nano`).
5. **Waybar layout selection** — lets you choose between three Waybar layouts (desktop, laptop, or desktop-primary-display-only) by repointing the `config` symlink in `~/.config/waybar/`.
6. **Waybar systemd service** — installs a user systemd unit so Waybar restarts on crash instead of relying on Hyprland's `exec-once`, and adds a KDE autostart entry to stop it when logging into Plasma instead.
7. **Monitor config** — if you're in an active Hyprland session, launches `nwg-displays` so you can arrange your outputs and generate `~/.config/hypr/monitors.conf` and `workspaces.conf`. If you run the installer from KDE (or before your first Hyprland login), this step is skipped with instructions to run it manually later — `nwg-displays` only supports sway/Hyprland/Niri and can't run under Plasma.
8. **Cursor theme** — clones [accurse](https://github.com/ATM-Jahid/accurse), patches its bundled Breeze theme (recolored, extended size set), compiles it, and installs the result to `~/.local/share/icons/AC-Breeze`.
9. **Dynamic-cursors Hyprland plugin** — adds and enables [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) via `hyprpm`. Skipped (not failed) if `hyprpm` isn't available or the build fails — a mismatched Hyprland header set is the usual cause, and generally means Hyprland itself needs updating first.
10. **Configure Spicetify** — if `spicetify` and a native Spotify install are both detected, runs `spicetify backup apply`, fetches the Sleek theme if it's not already present, and points `config-xpui.ini` at the matugen-generated color scheme.
11. **Configure Vesktop** — if Vesktop is detected (native or Flatpak), ensures its themes directory exists and best-effort enables the Midnight Discord theme in Vencord's own settings.
12. **Wallpaper-changer** — clones (or updates) [FC3243D4/Wallpaper-changer](https://github.com/FC3243D4/Wallpaper-changer) as a sibling directory next to this repo and runs its own installer.
13. **KDE autostart entry for awww-daemon** — adds the `.desktop` file so the wallpaper daemon starts under a KDE Plasma session (see [Wallpapers](#wallpapers-awww) below for the desktop-icon caveat).

Re-running `install.sh` is safe — it'll pick up dependency and config changes without clobbering local edits or reinstalling things that are already present.

## Wallpapers (awww)

Wallpapers are set and managed via [awww](https://codeberg.org/LGFae/awww), driven by the [Wallpaper-changer](https://github.com/FC3243D4/Wallpaper-changer) scripts that `install.sh` clones and installs alongside this repo. matugen reads the active wallpaper to generate the accent-color theme, so awww is the thing actually driving the whole theming pipeline, not just wallpaper display.

The repo includes a `.desktop` file to autostart the awww daemon under a **KDE Plasma** session, since Plasma doesn't pick up Hyprland's own `exec-once` autostart mechanism.

> **Heads up:** enabling this autostart on KDE hides all icons on the desktop. awww's rendering surface occupies the same desktop layer Plasma's own Folder View uses to display desktop icons, so the two conflict — you get the awww wallpaper, but Plasma's desktop icon layer no longer shows through. If you rely on desktop icons under your KDE session, you'll want to either skip enabling that `.desktop` autostart entry there, or accept the tradeoff and access files via Dolphin/the app launcher instead. This doesn't affect the Hyprland session, where there's no desktop icon layer to conflict with in the first place.

## Icons

`iconPatcher.sh` and the per-app patcher scripts (`vscodePatcher.sh`, `discordPatcher.sh`, `ferdiumIconPatcher.sh`, `spicetifyPostHook.sh`, browser patchers, etc.) recolor a shared set of monochrome SVG icons to match the matugen-derived accent color, then push the result out to each app's icon lookup path. Icons are recolored via their `currentColor` stroke/fill (or, for a handful of flat-hex legacy icons, a direct hex substitution), then dropped into place per app — a local `file://` icon override for Ferdium's recipes, the app's own resource directory for VS Code, and so on.

The icon set itself lives in the [Wallpaper-changer](https://github.com/FC3243D4/Wallpaper-changer) repo (installed alongside this one — see step 12 above), not in this repo. It's a mix of [Tabler Icons](https://tabler.io/icons) (MIT licensed) for general/category icons and custom icons for specific app/game overrides. See that repo for the icon files and license details.

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
| `pciutils` (`lspci`) | GPU vendor detection for the NVIDIA env toggle |
| KDE application suite | Full KDE app set for the hybrid session (Dolphin, Konsole, etc.) — also transitively provides `kwriteconfig6`/`kreadconfig6`, used by matugen's KDE color-scheme patcher |
| `plasma-apply-colorscheme` | Applies generated KDE color schemes |
| `hyprpolkitagent` | Polkit authentication agent for the Hyprland session (installed via COPR on Fedora; built from source on Debian/Ubuntu) |
| `openrgb` (optional) | Syncs the wallpaper's dominant color to RGB peripherals |
| `spicetify-cli` | Spotify theming CLI, used to apply the matugen-generated color scheme (via the Sleek theme) — installed via the AUR on Arch, upstream's own install script elsewhere |
| `vesktop` (optional) | Discord client with built-in Vencord, used for the matugen-generated Midnight Discord theme — installed via the AUR on Arch, Flatpak elsewhere. Not required if you don't use Discord/Vesktop |
| `awww` (via Wallpaper-changer) | Wallpaper daemon that drives the whole theming pipeline — see [Wallpapers](#wallpapers-awww) above |

### General utilities

Base set carried over from JaKooLit's Hyprland-Dots: `cliphist`, `curl`, `grim`, `gvfs`, `gvfs-mtp`, `inxi`, `jq`, `kitty`, `libspng`, `nano`, `network-manager-applet`, `pamixer`, `pavucontrol`, `playerctl`, `python-requests`, `python-pyquery`, `slurp`, `swappy`, `topgrade`, `wget`, `wl-clipboard`, `wlogout`, `xdg-user-dirs`, `xdg-utils`, `yad`.

`cliphist` and `topgrade` are installed via `go install`/`cargo install` respectively where not natively packaged (Debian/Ubuntu for `cliphist`; everywhere except Arch's AUR and Fedora's COPR for `topgrade`, which has no official package on any of the four supported distros). `gvfs-mtp` pulls in extra companion packages on Debian/Ubuntu (`gvfs-backends`) and openSUSE (`gvfs-backend`, `mtpfs`, `mtp-tools`, `libmtp-runtime`) since MTP support is split across several packages on those distros.

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