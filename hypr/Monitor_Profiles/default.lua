-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
-- Default monitor config
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Use `hyprctl monitors` to list available outputs and their names.

-- ── ACTIVE MONITOR RULES ─────────────────────────────────────────────────────

-- Fallback: preferred mode, auto position, scale 1 (catches any unconfigured monitor)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- High refresh rate (uncomment to prefer highest Hz over resolution)
-- hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })

-- High resolution (uncomment to prefer highest resolution over refresh rate)
-- hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

-- NOTE: For laptops, see Laptops.lua regarding display wake behaviour.
-- Related issue: https://github.com/hyprwm/Hyprland/issues/4090


-- ── SPECIFIC MONITOR EXAMPLES (uncomment and adapt as needed) ─────────────────

-- Laptop internal display
-- hl.monitor({ output = "eDP-1", mode = "preferred",      position = "auto", scale = 1 })
-- hl.monitor({ output = "eDP-1", mode = "2560x1440@165",  position = "0x0",  scale = 1 })

-- External displays
-- hl.monitor({ output = "DP-3",    mode = "1920x1080@240", position = "auto", scale = 1 })
-- hl.monitor({ output = "DP-1",    mode = "preferred",     position = "auto", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred",    position = "auto", scale = 1 })

-- QEMU / VirtualBox / VMware
-- hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })


-- ── DISABLE A MONITOR ────────────────────────────────────────────────────────

-- hl.monitor({ output = "HDMI-A-1", disabled = true })


-- ── MIRROR EXAMPLES ──────────────────────────────────────────────────────────

-- hl.monitor({ output = "DP-3",    mode = "1920x1080@60",  position = "0x0", scale = 1, mirror = "DP-2" })
-- hl.monitor({ output = "",        mode = "preferred",     position = "auto", scale = 1, mirror = "eDP-1" })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0", scale = 1, mirror = "eDP-1" })


-- ── 10-BIT SUPPORT ───────────────────────────────────────────────────────────
-- NOTE: Hyprland border colours do not support 10-bit.
-- NOTE: Some apps (e.g. OBS) may show a black screen when capturing with 10-bit enabled.

-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, bitdepth = 10 })


-- ── TRANSFORM & RESERVED AREA ────────────────────────────────────────────────
-- transform: 0=normal 1=90° 2=180° 3=270° 4=flipped 5=flipped+90° 6=flipped+180° 7=flipped+270°
-- reserved_area: extra pixels reserved beyond what bars already claim (top, bottom, left, right)

-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1, transform = 0 })
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1, reserved_area = { 10, 10, 10, 49 } })


-- ── WORKSPACE → MONITOR RULES ────────────────────────────────────────────────
-- See https://wiki.hyprland.org/Configuring/Workspace-Rules/
-- Defined in UserConfigs/WorkspaceRules.lua