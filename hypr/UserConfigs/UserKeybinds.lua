-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- This is where you put your own keybinds. Be Mindful to check as well ~/.config/hypr/configs/Keybinds.conf to avoid conflict
-- if you think I should replace the Pre-defined Keybinds in ~/.config/hypr/configs/Keybinds.conf , submit an issue or let me know in DC and present me a valid reason as to why, such as conflicting with global shortcuts, etc etc

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more settings and variables
-- See also Laptops.conf for laptops keybinds 

-- /* ---- ✴️ Variables ✴️ ---- */  #
local mainMod = "SUPER"
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local UserScripts = os.getenv("HOME") .. "/.config/hypr/UserScripts"
local UserConfigs = os.getenv("HOME") .. "/.config/hypr/UserConfigs"
local WallpapersScripts = os.getenv("HOME") .. "/.config/WallpaperChanger"


--  IMPORTANT: If you want to remap and existing keybind you MUST unbindd it first 

-- The bindings are CASE SENSITIVE. We suggest you copy the exisitng binding here
--  Then change `bindd` to `unbind`

-- E.g. 
-- hl.unbind( mainMod .. " + Return")
-- hl.bind( mainMod .. " + Return ", hl.dsp.exec_cmd("ghostty"), { description = "Launch terminal" })

-- If you are ADDING a bindd, make sure you include the description 
-- Other the keybind search menu might not show it properly 

-- E.g.
-- hl.bind( mainMod .. " + Z", hl.dsp.exec_cmd("myApp"), { description = "Launch myApp" })