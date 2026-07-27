--Commands and Apps to be executed at launch (vendor defaults)

hl.on("hyprland.start", function()
    local cmds = {
        -- Environment
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",

        -- Init scripts
        "scripts/KeybindsLayoutInit.sh",

        -- Drop-down terminal
        -- See Bug#810 https://github.com/JaKooLit/Hyprland-Dots/issues/810#issuecomment-3351947644
        os.getenv("HOME") .. "/.config/hypr/scripts/Dropterminal.sh kitty &",

        -- Polkit
        --"scripts/Polkit.sh",
        "systemctl --user start hyprpolkitagent",

        -- System tray / shell
        "nm-applet --indicator",
        -- "nm-tray",  -- For Ubuntu
        "swaync",
        -- "ags",
        "blueman-applet",
        "qs -c overview",  -- Quickshell Overview

        -- Clipboard manager
        "wl-paste --type text --watch cliphist store",
        "wl-paste --type image --watch cliphist store",

        -- Idle / lock
        "hypridle",

        -- Disabled extras:
        -- "scripts/Polkit-NixOS.sh",   -- Gnome polkit for NixOS
        -- "scripts/PortalHyprland.sh", -- force-start xdg-desktop-portal-hyprland

        --reload hyprland to enable plugins
        "hyprpm reload -n",

        "ags",
        "systemctl --user import-environment PRIMARY_DISPLAY && dbus-update-activation-environment --systemd PRIMARY_DISPLAY",

        -- for dolphin apps menu
        "$HOME/.config/hypr/scripts/login-kde-apps.sh",

        --wallpaper stuff
        "awww-daemon",
        "sh -c 'sleep 2 && $HOME/.config/WallpaperChanger/WallpaperApplicator.sh random'", --select random wallpaper on startup, delay to ensure symlink update is done

        --kded6 watcher
        "$HOME/.config/hypr/scripts/kded6-fix.sh",

        --setting primary display
        --"xrandr --output X --primary",
    }

    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end)
