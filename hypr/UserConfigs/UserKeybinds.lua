-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- This is where you put your own keybinds. Be Mindful to check as well ~/.config/hypr/configs/Keybinds.conf to avoid conflict
-- if you think I should replace the Pre-defined Keybinds in ~/.config/hypr/configs/Keybinds.conf , submit an issue or let me know in DC and present me a valid reason as to why, such as conflicting with global shortcuts, etc etc

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more settings and variables
-- See also Laptops.conf for laptops keybinds 

-- /* ---- ✴️ Variables ✴️ ---- */  #
local mainMod = "SUPER"
local scriptsDir = "$HOME/.config/hypr/scripts"
local UserScripts = "$HOME/.config/hypr/UserScripts"
local UserConfigs = "$HOME/.config/hypr/UserConfigs"
local WallpapersScripts = "$HOME/.config/WallpaperChanger"

--  IMPORTANT: If you want to remap and existing keybind you MUST unbindd it first 

-- The bindings are CASE SENSITIVE. We suggest you copy the exisitng binding here
--  Then change `bindd` to `unbind`

-- E.g. 
-- hl.unbind( mainMod .. " + Return")
-- hl.bind( mainMod .. " + Return ", hl.dsp.exec_cmd("ghostty") { description = "Launch terminal" })

-- If you are ADDING a bindd, make sure you include the description 
-- Other the keybind search menu might not show it properly 

-- E.g.
-- hl.bind( mainMod .. " + Z", hl.dsp.exec_cmd("myApp") { description = "Launch myApp" })

hl.unbind( mainMod .. " + W")
hl.bind( mainMod .. " + W ", hl.dsp.exec_cmd(WallpapersScripts .. "/WallpaperMenu.sh"), { description = "Select Wallpaper" })

hl.unbind("CTRL + ALT + W")
hl.bind("CTRL + ALT + W ", hl.dsp.exec_cmd(WallpapersScripts .. "/WallpaperApplicator.sh random"), { description = "Random Wallpaper" })

hl.unbind( mainMod .. " + ALT + R")
hl.bind( mainMod .. " + ALT + R ", hl.dsp.exec_cmd(WallpapersScripts .. "/themeRefresher.sh"), { description = "Refresh Bar and Menus" })

hl.bind( mainMod .. " + CTRL + SHIFT + S ", hl.dsp.exec_cmd(WallpapersScripts .. "/WallpaperApplicator.sh random sfw"), { description = "Random SFW Wallpaper" })
hl.bind( mainMod .. " + CTRL + SHIFT + N ", hl.dsp.exec_cmd(WallpapersScripts .. "/WallpaperApplicator.sh random nsfw"), { description = "Random NSFW Wallpaper" })
