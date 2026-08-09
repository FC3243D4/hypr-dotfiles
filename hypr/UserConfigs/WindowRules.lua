--https://wiki.hypr.land/Configuring/Basics/Window-Rules/

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
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, workspace = 1 })

-- Solaar
hl.window_rule({ match = { class = "^([Ss]olaar)$" }, workspace = 5 })

-- Localsend
hl.window_rule({ match = { class = "^([Ll]ocalsend)$" }, workspace = 5 })




