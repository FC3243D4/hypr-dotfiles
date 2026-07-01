--https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- SourceGit
hl.window_rule({ match = { class = "^(SourceGit)$" }, 
    tag = "+git",
    no_blur = true
    --stay_focused = true
})

-- Gimp
hl.window_rule({ match = { class = "^(org.gimp.GIMP)$" }, workspace = "4" })

-- Plasma System Monitor
hl.window_rule({ match = { class = "^(org.kde.plasma-systemmonitor)$" }, 
    no_blur = true, 
    border_size = 0, 
    border_color = 0x00000000, 
    workspace = "20", 
    fullscreen = true, 
    maximize = true, 
    rounding = 0, decorate = false, 
    no_dim = true, 
    opacity = "1 override 1 override 1 override", 
})

--conky
hl.window_rule({ match = { class = "^(conky)$" },
    no_blur = true,
    border_size = 0,
    border_color = 0x00000000,
    workspace = "20",
    fullscreen = true,
    rounding = 0, decorate = false,
    no_dim = true,
    opacity = "1 override 1 override 1 override",
})

-- Ferdium
hl.window_rule({ match = { class = "^(Ferdium)$" }, workspace = 1 })

-- Solaar
hl.window_rule({ match = { class = "^([Ss]olaar)$" }, workspace = 5 })

-- Localsend
hl.window_rule({ match = { class = "^([Ll]ocalsend)$" }, workspace = 5 })

-- 3D tags
hl.window_rule({ match = { class = "^([Bb]lender)$" }, tag = "+threeD" })
hl.window_rule({ match = { class = "^(OrcaSlicer)$" }, tag = "+threeD" })
hl.window_rule({ match = { class = "^([Ff]reecad)$" }, tag = "+threeD" })
hl.window_rule({ match = { class = "^(fusion360.exe)$" }, tag = "+threeD" })
hl.window_rule({ match = { class = "^([Ll]ycheeslicer)$" }, tag = "+threeD" })

-- Workspaces rules for tags
hl.window_rule({ match = { tag = "games*" }, workspace = 10 , opacity = "1 override 1 override 1 override" })
hl.window_rule({ match = { tag = "gamestore*" }, workspace = 9 })
hl.window_rule({ match = { tag = "git*" }, workspace = 7 })
hl.window_rule({ match = { tag = "threeD*" }, workspace = 3 })


