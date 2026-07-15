-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
-- Default settings
-- NOTE: some settings are in UserDecorAnimations.lua

local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.config({
    dwindle = {
        -- pseudotile = true,   -- removed in 0.55
        preserve_split = true,
        -- smart_split = true,
        special_scale_factor = 0.8,
    },

    master = {
        -- new_status = "master",
        -- new_on_top = true,
        mfact = 0.5,
        orientation = "center",
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
    },

    general = {
        resize_on_border        = true,
        extend_border_grab_area = 10,
        layout                  = os.getenv("DEFAULT_LAYOUT"),
    },

    input = {
        kb_layout  = "it",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",
        repeat_rate  = 50,
        repeat_delay = 300,

        sensitivity          = 0,  -- mouse sensitivity
        -- accel_profile     = "",  -- flat / adaptive / blank = libinput default
        numlock_by_default   = true,
        left_handed          = false,
        follow_mouse         = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing    = true,
            natural_scroll          = true,
            clickfinger_behavior    = false,
            middle_button_emulation = false,
            tap_to_click            = true,
            drag_lock               = false,
        },

        -- touchdevice (touchscreen)
        touchdevice = {
            enabled = true,
        },

        -- tablet
        tablet = {
            transform   = 0,
            left_handed = false,
        },
    },

    gestures = {
        workspace_swipe_distance          = 500,
        workspace_swipe_invert            = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio      = 0.5,
        workspace_swipe_create_new        = true,
        workspace_swipe_forever           = true,
        -- workspace_swipe_use_r          = true,
    },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        vrr                        = 2,
        mouse_move_enables_dpms    = true,
        enable_swallow             = false,
        swallow_regex              = "^(kitty)$",
        focus_on_activate          = false,
        initial_workspace_tracking = 0,
        middle_click_paste         = false,
        enable_anr_dialog          = true,   -- Application Not Responding dialog
        anr_missed_pings           = 15,     -- default of 1 is too low
        allow_session_lock_restore = true,   -- prevent lockscreen crash on resume
    },

    -- opengl = {
    --     nvidia_anti_flicker = true,
    -- },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = false,
    },

    cursor = {
        sync_gsettings_theme     = false,
        no_hardware_cursors      = true,   -- set to false to re-enable hardware cursors
        enable_hyprcursor        = true,
        warp_on_change_workspace = 2,
        no_warps                 = true,
    },

    debug = {
        vfr = true,
    },
})

-- Gestures (replaces old gesture = lines and workspace_swipe_* options)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 4-finger pinch zoom in/out (replaces the hyprctl keyword exec gestures)
hl.gesture({ fingers = 4, direction = "pinchout", action = "cursorZoom", zoom_level = 1.5, mode = "mult" })
hl.gesture({ fingers = 4, direction = "pinchin", action = "cursorZoom", zoom_level = 1/1.5, mode = "mult" })

-- 3-finger swipe up: overview toggle
hl.gesture({ fingers = 3, direction = "up", action = function()
    hl.dispatch(hl.dsp.exec_cmd(scriptsDir .. "/OverviewToggle.sh"))
end })