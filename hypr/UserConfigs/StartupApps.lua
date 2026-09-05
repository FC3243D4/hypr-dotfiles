local scriptsDir = "$HOME/.config/hypr/scripts"
local UserScripts = "$HOME/.config/hypr/UserScripts"

hl.on("hyprland.start", function()
    local cmds = {

    }
    
    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end)
