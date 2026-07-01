-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
-- Vendor defaults for window rules and layerrules
-- See https://wiki.hypr.land/Configuring/Window-Rules/ for more

-- ── TAGS ─────────────────────────────────────────────────────────────────────

-- browser
hl.window_rule({ match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },          tag = "+browser" })
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },                               tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" },                                                     tag = "+browser" }) -- Chrome PWAs
hl.window_rule({ match = { class = "^([Cc]hromium)$" },                                                           tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },                       tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },                                  tag = "+browser" })
hl.window_rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" },                                   tag = "+browser" })
hl.window_rule({ match = { class = "^(zen-alpha|zen)$" },                                                         tag = "+browser" })

-- notifications
hl.window_rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },  tag = "+notif" })

-- KooL settings
hl.window_rule({ match = { title = "^(KooL Quick Cheat Sheet)$" },  tag = "+KooL_Cheat" })
hl.window_rule({ match = { title = "^(KooL Hyprland Settings)$" },  tag = "+KooL_Settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" },   tag = "+KooL-Settings" })

-- terminal
hl.window_rule({ match = { class = "^(kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- email
hl.window_rule({ match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" },  tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" },            tag = "+email" })

-- projects
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code|code-url-handler)$" },       tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" },                       tag = "+projects" }) -- JetBrains IDEs
hl.window_rule({ match = { class = "^([Gg]lint)$" },                           tag = "+projects" })

-- screenshare
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

-- IM
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" },                      tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" },                                            tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" },                                 tag = "+im" })
hl.window_rule({ match = { class = "^(ZapZap|com.rtosta.zapzap)$" },                              tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },  tag = "+im" })
hl.window_rule({ match = { class = "^(teams-for-linux)$" },                                       tag = "+im" })
hl.window_rule({ match = { class = "^(im.riot.Riot|Element)$" },                                  tag = "+im" }) -- Element Matrix client

-- games
hl.window_rule({ match = { class = "^(gamescope)$" },      tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })

-- gamestore
hl.window_rule({ match = { class = "^([Ss]team)$" },                    tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" },                   tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, tag = "+gamestore" })

-- file-manager
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|[Dd]olphin)$" },  tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" },                                          tag = "+file-manager" })

-- wallpaper
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

-- multimedia
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
hl.window_rule({ match = { class = "^([Ss]potify)$" },   tag = "+multimedia" })

-- multimedia-video
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

-- settings
hl.window_rule({ match = { title = "^(ROG Control)$" },                                                       tag = "+settings" })
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" },                                                  tag = "+settings" }) -- wifi hotspot
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" },                                     tag = "+settings" }) -- disk usage analyzer
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" },                                      tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" },                                                     tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" },                                  tag = "+settings" }) -- archive manager
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },                    tag = "+settings" })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },    tag = "+settings" })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" },                                                tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)" },                                              tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },                         tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" },                                                           tag = "+settings" })

-- viewer
hl.window_rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, tag = "+viewer" }) -- system monitor
hl.window_rule({ match = { class = "^(evince)$" },                                                                      tag = "+viewer" }) -- document viewer
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe)$" },                                                         tag = "+viewer" }) -- image viewer


-- ── MULTIMEDIA VIDEO OVERRIDES ────────────────────────────────────────────────

hl.window_rule({ match = { tag = "multimedia_video*" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video*" }, opacity = "1.0 override 1.0 override" })


-- ── POSITION ─────────────────────────────────────────────────────────────────

-- warning: center on floating:1 causes menus to float and center too — left disabled
hl.window_rule({ match = { tag = "KooL_Cheat*" },                                                              center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" },                        center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" },                                                        center = true })
hl.window_rule({ match = { tag = "KooL-Settings*" },                                                           center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" },                                                        center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },     center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },                     center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" },                                                         center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "72%", "7%" } })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, move = { "72%", "7%" } })


-- ── IDLE INHIBIT ─────────────────────────────────────────────────────────────

hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })


-- ── WORKSPACES ───────────────────────────────────────────────────────────────

hl.window_rule({ match = { tag = "projects*" },  workspace = 2 })
hl.window_rule({ match = { tag = "gamestore*" }, workspace = 5 })
hl.window_rule({ match = { tag = "games*" },     workspace = 8 })

-- silent workspace assignments (disabled by default)
-- hl.window_rule({ match = { tag = "screenshare*" }, workspace = "4 silent" })
-- hl.window_rule({ match = { class = "^(virt-manager)$" }, workspace = "6 silent" })
-- hl.window_rule({ match = { class = "^(.virt-manager-wrapped)$" }, workspace = "6 silent" })
-- hl.window_rule({ match = { tag = "multimedia*" }, workspace = "9 silent" })


-- ── FLOAT ────────────────────────────────────────────────────────────────────

hl.window_rule({ match = { tag = "KooL_Cheat*" },                                          float = true })
hl.window_rule({ match = { tag = "wallpaper*" },                                           float = true })
hl.window_rule({ match = { tag = "settings*" },                                            float = true })
hl.window_rule({ match = { tag = "viewer*" },                                              float = true })
hl.window_rule({ match = { tag = "KooL-Settings*" },                                       float = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)$" },            float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator)", title = "(Calculator)" },     float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" },                float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" },                               float = true })
--hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, float = true })
--hl.window_rule({ match = { class = "^([Ff]erdium)$" },                                     float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" },                             float = true })
--hl.window_rule({ match = { title = "^(Firefox)$" },                                        float = true })

-- float popups and dialogues
hl.window_rule({ match = { title = "^(Authentication Required)$" },                                                           float = true, center = true })
hl.window_rule({ match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },    float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$",      title = "negative:(Heroic Games Launcher)" },      float = true })
hl.window_rule({ match = { class = "^([Ss]team)$",                         title = "negative:^([Ss]team)$" },                 float = true })
hl.window_rule({ match = { class = "([Tt]hunar)",                          title = "negative:(.*[Tt]hunar.*)" },              float = true })

hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" },                                                           float = true, center = true, size = { "70%", "60%" } })
hl.window_rule({ match = { title = "^(Save As)$" },                                                                           float = true, center = true, size = { "70%", "60%" } })
hl.window_rule({ match = { initial_title = "(Open Files)" },                                                                  float = true, size = { "70%", "60%" } })

-- KooL's Dots YAD for setting SDDM background
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true, center = true, size = { "16%", "12%" } })


-- ── OPACITY ──────────────────────────────────────────────────────────────────

hl.window_rule({ match = { tag = "browser*" },                                  opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { tag = "projects*" },                                 opacity = "0.95 override 0.8 override" })
hl.window_rule({ match = { tag = "im*" },                                       opacity = "0.94 override 0.86 override" })
hl.window_rule({ match = { tag = "multimedia*" },                               opacity = "0.9 override 0.5 override" })
hl.window_rule({ match = { tag = "file-manager*" },                             opacity = "0.9 override 0.8 override" })
hl.window_rule({ match = { tag = "terminal*" },                                 opacity = "0.9 override 0.7 override" })
hl.window_rule({ match = { tag = "terminal*", workspace = 1 },                  opacity = "0.9 override 0 override" })
hl.window_rule({ match = { tag = "settings*" },                                 opacity = "0.9 override 0.7 override" })
hl.window_rule({ match = { tag = "viewer*" },                                   opacity = "0.82 override 0.75 override" })
hl.window_rule({ match = { tag = "wallpaper*" },                                opacity = "0.9 override 0.7 override" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 override 0.7 override" })
hl.window_rule({ match = { class = "^(deluge)$" },                              opacity = "0.9 override 0.8 override" })
hl.window_rule({ match = { class = "^(seahorse)$" },                            opacity = "0.9 override 0.8 override" }) -- gnome-keyring gui
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" },                  opacity = "0.95 override 0.75 override" })


-- ── SIZE ─────────────────────────────────────────────────────────────────────

hl.window_rule({ match = { tag = "KooL_Cheat*" },                                           size = { "65%", "90%" } })
hl.window_rule({ match = { tag = "wallpaper*" },                                            size = { "70%", "70%" } })
hl.window_rule({ match = { tag = "settings*" },                                             size = { "70%", "70%" } })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },  size = { "60%", "70%" } })
hl.window_rule({ match = { class = "^([Ff]erdium)$" },                                      size = { "60%", "70%" } })

-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = { "25%", "25%" } })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, size = { "25%", "25%" } })


-- ── PIN & EXTRAS ─────────────────────────────────────────────────────────────

hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true, keep_aspect_ratio = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, pin = true })


-- ── BLUR & FULLSCREEN ────────────────────────────────────────────────────────

hl.window_rule({ match = { tag = "games*" }, no_blur = true, fullscreen = true })


-- ── INTELLIJ / JETBRAINS ─────────────────────────────────────────────────────

-- Prevent focus stealing from tooltip-like windows in JetBrains IDEs
hl.window_rule({ match = { class = "^(jetbrains-.*)" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)" },       no_initial_focus = true })

-- ── LAYER RULES ──────────────────────────────────────────────────────────────

hl.layer_rule({ match = { namespace = "rofi" },                blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" },       blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.5 })