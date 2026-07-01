-- These configs are mostly for laptops. This is addendum to Keybinds.lua

local mainMod = "SUPER"
local touchpadDevice = "asue1209:00-04f3:319f-touchpad"

-- Keyboard brightness
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("scripts/BrightnessKbd.sh --dec"), { repeating = true, description = "Decrease keyboard brightness" })
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("scripts/BrightnessKbd.sh --inc"), { repeating = true, description = "Increase keyboard brightness" })

-- ASUS-specific keys
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"),    { description = "ASUS Armory crate button" })
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"),   { description = "Switch keyboard RGB profile" })
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"),    { description = "Change fan profile" })

-- Monitor brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("scripts/Brightness.sh --dec"), { repeating = true, description = "Decrease monitor brightness" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("scripts/Brightness.sh --inc"), { repeating = true, description = "Increase monitor brightness" })

-- Touchpad toggle
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("scripts/TouchPad.sh"), { description = "Toggle touchpad" })

-- Screenshots via F6 (no PrintSrc button)
hl.bind(mainMod .. " + F6",             hl.dsp.exec_cmd("scripts/ScreenShot.sh --now"),    { description = "Screenshot now" })
hl.bind(mainMod .. " + SHIFT + F6",     hl.dsp.exec_cmd("scripts/ScreenShot.sh --area"),   { description = "Screenshot (area)" })
hl.bind(mainMod .. " + CTRL + F6",      hl.dsp.exec_cmd("scripts/ScreenShot.sh --in5"),    { description = "Screenshot (5s delay)" })
hl.bind(mainMod .. " + ALT + F6",       hl.dsp.exec_cmd("scripts/ScreenShot.sh --in10"),   { description = "Screenshot (10s delay)" })
hl.bind("ALT + F6",                     hl.dsp.exec_cmd("scripts/ScreenShot.sh --active"), { description = "Screenshot active window" })

-- Touchpad device config
hl.device({
    name    = touchpadDevice,
    enabled = true,
})