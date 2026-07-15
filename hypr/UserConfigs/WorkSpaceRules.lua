--[[ https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

NOTE: THIS IS NOT BEING SOURCED by hyprland
It is only here as a guide if you want to do it manually
The file you should edit is ~/.config/hypr/workspaces.conf
Since that is the work space rules being sourced by hyprland
use nwg-displays to handle your workspace rules.

You can set workspace rules to achieve workspace-specific behaviors. --]]



-- Assigning workspace to a certain monitor. Below are just examples
--hl.workspace_rule({ workspace = "20", monitor = "HDMI-A-1" })


-- example rules (from wiki)
--hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false })
--hl.workspace_rule({ workspace = "name:coding", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true, monitor = "DP-1" })
--hl.workspace_rule({ workspace = "8", border_size = 8 })
--hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
--hl.workspace_rule({ workspace = "name:gaming", monitor = "desc:Chimei Innolux Corporation 0x150C", default = true })
--hl.workspace_rule({ workspace = "5", on_created_empty = "[float] firefox" })
--hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
--hl.workspace_rule({ workspace = "15", animation = "slidevert", default_name = "slider" })

--persistance
-- persist all 20 workspaces
for i = 1, os.getenv("PERSISTANT_WORKSPACES") do
    hl.workspace_rule({
        workspace = tostring(i),
        persistent = true,
    })
end

--specific workspace layout override
--add here your override for the layout of specific workspace, for example
--hl.workspace_rule({ workspace = "3", layout = "scrolling" })
--hl.workspace_rule({ workspace = "2", layout = "dwindle" })
--hl.workspace_rule({ workspace = "1", layout = "master" })
