-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more variable settings
-- These configs are mostly for laptops. This is addemdum to Keybinds.conf

local mainMod = SUPER
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local UserConfigs = os.getenv("HOME") .. "/.config/hypr/UserConfigs"

-- Below are useful when you are connecting your laptop in external display
-- Suggest you edit below for your laptop display
-- From WIKI This is to disable laptop monitor when lid is closed.
-- consult https://wiki.hypr.land/Configuring/Basics/Binds/#switches
--hl.bind("switch:off:Lid Switch",  hl.monitor({ output = "eDP-1", disable = false }))
--hl.bind("switch:on:Lid Switch", hl.monitor({ output = "eDP-1", disable = true }))
