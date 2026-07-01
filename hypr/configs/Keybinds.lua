-- Default Keybinds
-- visit https://wiki.hyprland.org/Configuring/Binds/ for more info

-------------------
---- VARIABLES ----
-------------------

local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- keys 1–0 (codes 10–19) and numpads (codes 79–90)
local wsKeyCodes = {
    { code = 10, ws = 1 },  { code = 11, ws = 2 },  { code = 12, ws = 3 },
    { code = 13, ws = 4 },  { code = 14, ws = 5 },  { code = 15, ws = 6 },
    { code = 16, ws = 7 },  { code = 17, ws = 8 },  { code = 18, ws = 9 },
    { code = 19, ws = 10 }, { code = 87, ws = 11 },  { code = 88, ws = 12 },
    { code = 89, ws = 13 }, { code = 83, ws = 14 },  { code = 84, ws = 15 },
    { code = 85, ws = 16 }, { code = 79, ws = 17 },  { code = 80, ws = 18 },
    { code = 81, ws = 19 }, { code = 90, ws = 20 },
}

---------------------------------------------------------------------------------------------------
---- settings for User defaults apps - set your default terminal and file manager on this file ----
---------------------------------------------------------------------------------------------------
require("UserConfigs/01-UserDefaults") -- Set your defaults editor through ENV in ~/.config/hypr/UserConfigs/01-UserDefaults.lua

------------------
---- STANDARD ----
------------------
-- Common shortcuts
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "app launcher" })
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("xdg-open https://"),                                                       { description = "open default browser" })
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd(scriptsDir .. "/OverviewToggle.sh"),                                        { description = "desktop overview" }) -- toggles quickshell or ags overview (tries QS first, falls back to AGS)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term),                                                                   { description = "open terminal" })
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(files),                                                                  { description = "open file manager" })

---------------------------
---- FEATURES / EXTRAS ----
---------------------------
hl.bind(mainMod .. " + H",                hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"),                                               { description = "show keybinds cheat sheet" })
hl.bind(mainMod .. " + ALT + R",          hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"),                                                { description = "refresh bar and menus" })
hl.bind(mainMod .. " + ALT + E",          hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"),                                              { description = "emoji menu" })
hl.bind(mainMod .. " + S",                hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"),                                             { description = "web search" })
hl.bind(mainMod .. " + CTRL + S",         hl.dsp.exec_cmd("rofi -show window"),                                                        { description = "window switcher" })
hl.bind(mainMod .. " + ALT + O",          hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"),                                             { description = "toggle blur" })
hl.bind(mainMod .. " + SHIFT + G",        hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"),                                               { description = "toggle game mode" })
hl.bind(mainMod .. " + ALT + L",          hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"),                                           { description = "toggle master/dwindle layout" })
hl.bind(mainMod .. " + ALT + V",          hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"),                                            { description = "clipboard manager" })
hl.bind(mainMod .. " + CTRL + R",         hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh"),                                      { description = "rofi theme selector" })
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"), { description = "rofi theme selector (modified)" })

hl.bind(mainMod .. " + SHIFT + F",        hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }),           { description = "toggle fullscreen" })
hl.bind(mainMod .. " + CTRL + F",         hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }),            { description = "toggle maximize" })
hl.bind(mainMod .. " + SPACE",            hl.dsp.window.float({ action = "toggle" }),                                     { description = "toggle floating" })
hl.bind(mainMod .. " + SHIFT + Return",   hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh" .. term),                      { description = "dropdown terminal" })

-- Waybar / Bar related
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"),          { description = "toggle waybar" })
hl.bind(mainMod .. " + CTRL + B",       hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"), { description = "waybar styles menu" })
hl.bind(mainMod .. " + ALT + B",        hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "waybar layout menu" })

-----------------------------------------
---- FEATURES / EXTRAS (UserScripts) ----
-----------------------------------------
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(scriptsDir .. "/WallpaperSelect.sh"),            { description = "select wallpaper" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(scriptsDir .. "/WallpaperEffects.sh"),           { description = "wallpaper effects" })
hl.bind("CTRL + ALT + W",          hl.dsp.exec_cmd(scriptsDir .. "/WallpaperRandomAspectRatio.sh"), { description = "random wallpaper" })
hl.bind(mainMod .. " + CTRL + O",  hl.dsp.exec_cmd("hyprctl setprop active opaque toggle"),         { description = "toggle active window opacity" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"),                   { description = "search keybinds" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"),                 { description = "animations menu" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(scriptsDir .. "/ZshChangeTheme.sh"),             { description = "change oh-my-zsh theme" })
hl.bind("ALT + SHIFT + A",         hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"),       { description = "switch keyboard layout globally" })
hl.bind("SHIFT + ALT + A",         hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"),     { description = "switch keyboard layout per-window" })
hl.bind(mainMod .. " + ALT + C",   hl.dsp.exec_cmd(scriptsDir .. "/RofiCalc.sh"),                   { description = "calculator" })

-- Move current workspaces to monitors (left right up or down)
hl.bind(mainMod .. " + CTRL + F9",  hl.dsp.exec_cmd("movecurrentworkspacetomonitor l"), { description = "move workspace to left monitor" })
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.exec_cmd("movecurrentworkspacetomonitor r"), { description = "move workspace to right monitor" })
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.exec_cmd("movecurrentworkspacetomonitor u"), { description = "move workspace to up monitor" })
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.exec_cmd("movecurrentworkspacetomonitor d"), { description = "move workspace to down monitor" })


----------------
---- SYSTEM ----
----------------
hl.bind(mainMod .. " + Q",         hl.dsp.window.close(),                                    { description = "close active window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"),   { description = "terminate active process" })
hl.bind("CTRL + ALT + L",          hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"),          { description = "lock screen" })
hl.bind("CTRL + ALT + P",          hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"),             { description = "powermenu" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"),                  { description = "notification panel" })
hl.bind(mainMod .. " +SHIFT + E",  hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh"), { description = "quick settings menu" })

-- Master Layout
hl.bind(mainMod .. " + CTRL + D",      hl.dsp.layout("removemaster"),   { description = "Remove master" })
hl.bind(mainMod .. " + I",             hl.dsp.layout("addmaster"),      { description = "Add master" })
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "Swap with master" })

-- Dwindle Layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "Toggle split (Dwindle)" })
hl.bind(mainMod .. " + P",         hl.dsp.layout("pseudo"),      { description = "Toggle pseudo (Dwindle)" })

-- Works on either layout (Master or Dwindle)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("splitratio 0.3"), { description = "Set split ratio to 0.3" })

-- Cycle windows; if floating bring to top
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Cycle next window" })
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top(),                { description = "Bring active to top" })

-- Special Keys / Hot Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("scripts/Volume.sh --inc"),         { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("scripts/Volume.sh --dec"),         { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("scripts/Volume.sh --toggle-mic"),  { locked = true, description = "Toggle mic mute" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("scripts/Volume.sh --toggle"),      { locked = true, description = "Toggle mute" })
hl.bind("XF86Sleep",            hl.dsp.exec_cmd("systemctl suspend"),               { locked = true, description = "Sleep" })
hl.bind("XF86Rfkill",           hl.dsp.exec_cmd("scripts/AirplaneMode.sh"),         { locked = true, description = "Airplane mode" })

-- Media controls
--hl.bind("XF86AudioPlayPause", hl.dsp.exec_cmd("scripts/MediaCtrl.sh --pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd("scripts/MediaCtrl.sh --pause"), { locked = true, description = "Pause" })
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd("scripts/MediaCtrl.sh --play"),  { locked = true, description = "Play" })
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd("scripts/MediaCtrl.sh --nxt"),   { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd("scripts/MediaCtrl.sh --prv"),   { locked = true, description = "Previous track" })
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd("scripts/MediaCtrl.sh --stop"),  { locked = true, description = "Stop" })

-- Screenshots
hl.bind(mainMod .. " + Print",                hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"),    { description = "Screenshot now" })
hl.bind(mainMod .. " + SHIFT + Print",        hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),   { description = "Screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print",         hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),    { description = "Screenshot in 5s" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"),   { description = "Screenshot in 10s" })
hl.bind("ALT + Print",                        hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "Screenshot active window" })

-- screenshot with swappy (another screenshot tool)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "Screenshot (swappy)" })

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0,  relative = true }),  { repeating = true, description = "Resize left (-50)" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }),  { repeating = true, description = "Resize right (+50)" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true, description = "Resize up (-50)" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true, description = "Resize down (+50)" })

-- Move windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })

-- Swap windows
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }), { description = "Swap window left" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window right" })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- Groups
hl.bind(mainMod .. " + G",           hl.dsp.group.toggle(),                              { description = "Toggle group" })
hl.bind(mainMod .. " + Tab",         hl.dsp.group.next(),                                { description = "Change group forward" })
hl.bind(mainMod .. " + CTRL + Tab",  hl.dsp.group.next(),                                { description = "Change active in group" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev(),                                { description = "Change group back" })
--hl.bind(mainMod .. " + CTRL + K",    hl.dsp.window.move_into_group({ direction = "l" }), { description = "Move left into group" })
--hl.bind(mainMod .. " + CTRL + L",    hl.dsp.window.move_into_group({ direction = "r" }), { description = "Move right into group" })
--hl.bind(mainMod .. " + CTRL + H",    hl.dsp.window.move_out_of_group(),                  { description = "Move active out of group" })

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }), { description = "Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { description = "Focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }), { description = "Focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }), { description = "Focus down" })

-- Workspace navigation
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace" })

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }),     { description = "Move to special workspace" })
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special(),                 { description = "Toggle special workspace" })


-- Switch workspaces and move windows to workspaces with keys 1-0 and numpads
for _, entry in ipairs(wsKeyCodes) do
    local key = "code:" .. entry.code
    hl.bind(mainMod .. " + " .. key,              hl.dsp.focus({ workspace = entry.ws }),           { description = "Workspace " .. entry.ws }) -- Switch
    hl.bind(mainMod .. " + SHIFT + " .. key,      hl.dsp.window.move({ workspace = entry.ws }),                { description = "Move to workspace " .. entry.ws }) -- Move and follow
    hl.bind(mainMod .. " + CTRL + " .. key,       hl.dsp.window.move({ workspace = entry.ws, follow = false }), { description = "Move silently to workspace " .. entry.ws }) -- Move silently
end

-- Bracket prev/next
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }),                { description = "Move to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }),                { description = "Move to next workspace" })
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }), { description = "Move silently to previous workspace" })
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "Move silently to next workspace" })

-- Scroll / period / comma through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind(mainMod .. " + period",     hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + comma",      hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
