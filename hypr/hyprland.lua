local gamemode = false

local path = os.getenv("HOME") .. "/.config/hypr/scripts/gamemode_status"
local f = io.open(path, "r")

if f then
    local val = f:read("*l")
    f:close()

    gamemode = (val == "true")
end

-- Sourcing external config files

-- Keybinds
require("configs/Keybinds") -- Pre-configured keybinds
require("UserConfigs/UserKeybinds") -- Put your own keybinds here

-- Load defaults, then user additions/overrides
require("configs/Startup_Apps") -- Pre-configured startup applications
require("UserConfigs/Startup_Apps") -- User-defined startup applications

require("configs/ENVariables") -- Environment variables (defaults)
require("UserConfigs/ENVariables") -- Environment variables (user)

-- For laptop related
require("configs/Laptops") -- Pre-configured laptop settings 
require("UserConfigs/Laptops") -- User-defined laptop settings
require("UserConfigs/LaptopDisplay") -- User-defined laptop display settings

-- Load defaults, then user additions
require("configs/WindowRules") -- Window Rules and Layer Rules (defaults)
require("UserConfigs/WindowRules") -- Window Rules and Layer Rules (user)

require("configs/SystemSettings") -- Default config for hypr
require("UserConfigs/UserSettings") -- Main Hyprland Settings

if gamemode then
    require("UserConfigs/UserDecorationsGameMode") -- Decorations config file for Game Mode (disabled by default)
    require("UserConfigs/UserAnimationsGameMode") -- Animation config file for Game Mode (disabled by default)
else
    require("UserConfigs/UserDecorations") -- Decorations config file
    require("UserConfigs/UserAnimations") -- Animation config file
end

--workspace rules
require("UserConfigs/WorkSpaceRules")

-- nwg-displays
require("monitors") -- User-defined monitor settings
require("workspaces") -- User-defined workspace settings

-- hyprcursor
require("hypr-dynamic-cursor") -- User-defined dynamic cursor plugin settings

-- hyprexpo
--require("UserConfigs/hyprexpo") -- User-defined hyprexpo plugin settings
