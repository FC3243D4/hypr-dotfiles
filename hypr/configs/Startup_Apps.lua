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
        -- "rog-control-center",
        "waybar",
        "qs -c overview",  -- Quickshell Overview

        -- Clipboard manager
        "wl-paste --type text --watch cliphist store",
        "wl-paste --type image --watch cliphist store",

        -- Rainbow borders (disabled)
        -- os.getenv("HOME") .. "/.config/hypr/UserScripts/RainbowBorders.sh",

        -- Idle / lock
        "hypridle",

        -- Disabled extras:
        -- "scripts/Polkit-NixOS.sh",   -- Gnome polkit for NixOS
        -- "scripts/PortalHyprland.sh", -- force-start xdg-desktop-portal-hyprland
    }

    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end)
