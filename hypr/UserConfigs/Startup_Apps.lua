local scriptsDir = "$HOME/.config/hypr/scripts"
local UserScripts = "$HOME/.config/hypr/UserScripts"

local RandomWallpaper = "$HOME/.config/WallpaperChanger/WallpaperApplicator.sh random"
local RandomWallpaperAuto = "$HOME/.config/WallpaperChanger/WallpaperRandomAuto.sh"

hl.on("hyprland.start", function()
    local cmds = {
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
