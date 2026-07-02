-- Set your defaults editor through ENV in ~/.config/hypr/UserConfigs/01-UserDefaults.lua

-----------------------------------
---- Toolkit Backend Variables ----
-----------------------------------
hl.env("GDK_BACKEND", "wayland,x11,*") -- Set GDK_BACKEND to wayland, x11, or auto-detect (default is auto-detect)
hl.env("QT_QPA_PLATFORM", "wayland;xcb") -- Set QT_QPA
hl.env("CLUTTER_BACKEND", "wayland") -- Set CLUTTER_BACKEND to wayland, x11, or auto-detect (default is auto-detect)

-- Run SDL2 applications on Wayland.
-- Remove or set to x11 if games that provide older versions of SDL cause compatibility issues
--hl.env("SDL_VIDEODRIVER", "wayland") -- Set SDL_VIDEODRIVER to wayland, or auto-detect (default is auto-detect)

----------------------------
---- XDG Specifications ----
----------------------------
hl.env("XDG_CURRENT_DESKTOP", "Hyprland") -- Set XDG_CURRENT_DESKTOP to Hyprland
hl.env("XDG_SESSION_DESKTOP", "Hyprland") -- Set XDG_SESSION_DESKTOP to Hyprland
hl.env("XDG_SESSION_TYPE", "wayland") -- Set XDG_SESSION_TYPE to wayland
--hl.env("GTK_THEME", "Breeze-Dark")

----------------------
---- QT Variables ----
----------------------
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM","wayland")

-----------------------------
---- hyprland-qt-support ----
-----------------------------
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-------------------------------------------------------------------------
---- xwayland apps scale fix (useful if you are use monitor scaling) ----
-------------------------------------------------------------------------
-- Set same value if you use scaling in Monitors.conf
-- 1 is 100% 1.5 is 150%
-- see https://wiki.hypr.land/Configuring/Advanced-and-Cool/XWayland/
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-----------------
---- firefox ----
-----------------
hl.env("MOZ_ENABLE_WAYLAND", "1")

--------------------------------------
---- electron >28 apps (may help) ----
--------------------------------------
-- https://www.electronjs.org/docs/latest/api/environment-variables
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- auto selects Wayland if possible, X11 otherwise

----------------
---- NVIDIA ----
----------------
-- This is from Hyprland Wiki. Below will be activated nvidia gpu detected
-- See hyprland wiki https://wiki.hypr.land/Nvidia/#environment-variables

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")

------------------------------------------------------------------
---- additional ENV's for nvidia. Caution, activate with care ----
------------------------------------------------------------------
--hl.env("GBM_BACKEND", "nvidia-drm")
--hl.env("__GL_GSYNC_ALLOWED", "1") #adaptive Vsync
--hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
--hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
--hl.env("WLR_DRM_NO_ATOMIC", "1")

------------------------------------
---- FOR VM and POSSIBLY NVIDIA ----
------------------------------------
--hl.env("LIBGL_ALWAYS_SOFTWARE", "1") -- Force software rendering for OpenGL applications. Warning. May cause hyprland to crash
--hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1") -- Allow wlroots to use software rendering. Warning. May cause hyprland to crash

------------------------
---- nvidia firefox ----
------------------------
-- check this post https://github.com/elFarto/nvidia-vaapi-driver#configuration
--hl.env("MOZ_DISABLE_RDD_SANDBOX", "1") -- Disable the RDD sandbox in Firefox, which can cause issues with NVIDIA drivers.
--hl.env("EGL_PLATFORM", "wayland") -- Set EGL_PLATFORM to wayland for

------------------------------------------------------------
---- Aquamarine Environment Variables (Hyprland > 0.45) ----
------------------------------------------------------------
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/#aquamarine-environment-variables
--hl.env("AQ_TRACE", "1") -- Enables more verbose logging.
--hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0") -- Set an explicit list of DRM devices (GPUs) to use. It’s a colon-separated list of paths, with the first being the primary. E.g. /dev/dri/card1:/dev/dri/card0
--hl.env("AQ_MGPU_NO_EXPLICIT", "1") -- Disables explicit syncing on mgpu buffers
--hl.env("AQ_NO_MODIFIERS", "1") -- Disables modifiers for DRM buffers

----------------------------------------
---- Hyprland Environment Variables ----
----------------------------------------
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/#hyprland-environment-variables
--hl.env("HYPRLAND_TRACE", "1") -- Enables more verbose logging.
--hl.env("HYPRLAND_NO_RT", "1") -- Disables realtime priority setting by Hyprland.
--hl.env("HYPRLAND_NO_SD_NOTIFY", "1") -- If systemd, disables the 'sd_notify' calls.
--hl.env("HYPRLAND_NO_SD_VARS", "1") -- Disables management of variables in systemd and dbus activation environments.
