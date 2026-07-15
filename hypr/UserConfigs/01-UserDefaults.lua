-- These two are for UserKeybinds.conf & Waybar Modules

-- This is a file where you put your own default apps, default search Engine etc

-- Set your default editor here uncomment and reboot to take effect.
-- NOTE, this will be automatically uncommented if you select neovim or vim to your default editor
hl.env("EDITOR", "code") -- default editor

term = "kitty" -- Terminal
files = "dolphin" -- File Manager

-- Default Search Engine for ROFI Search (SUPER S)
Search_Engine = "https://www.startpage.com/do/dsearch?q={}"

-- Primary display
hl.env("PRIMARY_DISPLAY", "x")

-- Number of persistant workspaces
hl.env("PERSISTANT_WORKSPACES", 10)

-- Default Layout
hl.env("DEFAULT_LAYOUT", "master")
