--[[ ---- 💫 https://github.com/JaKooLit 💫 ---- ]]--
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for syntax reference
-- These configs are mostly for laptops. This is addendum to Keybinds.lua

local mainMod = "SUPER"
local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"
local userConfigs = home .. "/.config/hypr/UserConfigs"

-- for disabling Touchpad. hyprctl devices to get device name.
local touchpadDevice = "asue1209:00-04f3:319f-touchpad"

-- Keyboard brightness (binde -> { repeating = true })
hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"),    { repeating = true, description = "Decrease keyboard brightness" }) -- decrease keyboard brightness
hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"),      { repeating = true, description = "Increase keyboard brightness" }) -- increase keyboard brightness

hl.bind("xf86Launch1", hl.dsp.exec_cmd("rog-control-center"),                                 { description = "ASUS Armory crate button" })
hl.bind("xf86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"),                                { description = "FN+F4 Switch keyboard RGB profile" })
hl.bind("xf86Launch4", hl.dsp.exec_cmd("asusctl profile -n"),                                 { description = "FN+F5 change of fan profiles (Quiet, Balance, Performance)" })

-- Monitor brightness (binde -> { repeating = true })
hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"),       { repeating = true, description = "Decrease monitor brightness" }) -- decrease monitor brightness
hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"),         { repeating = true, description = "Increase monitor brightness" }) -- increase monitor brightness

hl.bind("xf86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"),                  { description = "Toggle touchpad" }) -- disable touchpad

-- Screenshot keybindings using F6 (no PrintSrc button)
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"),            { description = "Take screenshot" }) -- screenshot
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),   { description = "Take area screenshot" }) -- screenshot (area)
hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),     { description = "Take delayed screenshot (5 secs)" }) -- screenshot (5 secs delay)
hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"),     { description = "Take delayed screenshot (10 secs)" }) -- screenshot (10 secs delay)
hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"),                 { description = "Take active window screenshot" }) -- screenshot (active window only)

local touchpadEnabled = true

hl.device({
  name = touchpadDevice,
  enabled = touchpadEnabled,
})