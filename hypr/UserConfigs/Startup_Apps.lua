local scriptsDir = "$HOME/.config/hypr/scripts"
local UserScripts = "$HOME/.config/hypr/UserScripts"

local RandomWallpaper = "$HOME/.config/WallpaperChanger/WallpaperApplicator.sh random"
local RandomWallpaperAuto = "$HOME/.config/WallpaperChanger/WallpaperRandomAuto.sh"

hl.on("hyprland.start", function()
    local cmds = {

    }
    
    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end)
