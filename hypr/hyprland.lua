local gamemode = false

local path = os.getenv("HOME") .. "/.config/hypr/scripts/gamemode_status"
local f = io.open(path, "r")

if f then
    local val = f:read("*l")
    f:close()

    gamemode = (val == "true")
end

-- Reads a status file instead of calling hyprctl live: hyprctl plugin list
-- is the only reliable source for "did it actually load" (vs. just "is the
-- .so built"), but it can't be called synchronously here — Hyprland
-- re-sources this file on its own main thread during any reload, so an IPC
-- call made mid-parse can deadlock waiting on that same reload. Instead,
-- pluginStatusChecker.sh writes this file once Hyprland is already fully up
-- (see Startup_Apps), and gets re-run manually after `hyprpm update`.
local function isPluginLoaded(name)
    local home = os.getenv("HOME") or ""
    local statusFile = home .. "/.config/hypr/scripts/" .. name .. "_status"
    local f = io.open(statusFile, "r")
    if not f then
        return false
    end

    local val = f:read("*l")
    f:close()

    return val == "true"
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

-- hypr-dynamic-cursors
if isPluginLoaded("dynamic-cursors") then
    -- pcall as a second safety net: the status file can go stale if the
    -- plugin breaks after Hyprland already started (no restart in between),
    -- so a failed require here degrades gracefully instead of erroring the
    -- whole config.
    local ok, err = pcall(require, "hypr-dynamic-cursor") -- User-defined dynamic cursor plugin settings
    if not ok then
        print("hypr-dynamic-cursor failed to load: " .. tostring(err))
    end
end