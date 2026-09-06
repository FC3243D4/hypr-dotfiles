#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# GDK backend. Change to either wayland or x11 if having issues
backend=wayland

# Check if rofi or yad is running and kill them if they are
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Launch yad with calculated width and height
# NOTE: under Wayland (GdkBackend=wayland) yad's window autosize routine
# doesn't reliably measure the --list content, so it can collapse to a
# tiny sliver. Force an explicit size instead of relying on autosize.
width=1000
height=750

GdkBackend=$backend yad \
    --center \
    --title="KooL Quick Cheat Sheet" \
    --width="$width" \
    --height="$height" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Command: \
    --timeout-indicator=bottom \
"ESC" "close this app" "" " = " "SUPER KEY (Windows Key Button)" "(SUPER KEY)" \
" K" "Searchable Keybinds" "(Search all Keybinds via rofi)" \
" CTRL Esc" "KooL Hyprland Settings Menu" "" \
"" "" "" \
" enter" "Terminal" "(kitty)" \
" Shift enter" "DropDown Terminal" " Q to close" \
" B" "Launch Browser" "(Default browser)" \
" CTRL Tab" "Desktop Overview" "(AGS - if opted to install)" \
" D" "Application Launcher" "(rofi-wayland)" \
" F" "Open File Manager" "" \
" S" "Google Search using rofi" "(rofi)" \
" Q" "close active window" "(not kill)" \
" Shift Q " "kills an active window" "(kill)" \
" V" "Clipboard Manager" "(cliphist)" \
" W" "Choose wallpaper" "(Wallpaper Menu)" \
" Shift W" "Random wallpaper" "(via swww)" \
" CTRL B" "Choose waybar styles" "(waybar styles)" \
" ALT B" "Choose waybar layout" "(waybar layout)" \
" R" "Run a full theme refresh" "you'll loose all unread notifications doing this!" \
" N" "Launch Notification Panel" "swaync Notification Center" \
" Print" "screenshot" "(grim)" \
" Shift Print" "Screenshot active window" "active window only" \
" CTRL Print" "screenshot region" "(grim + slurp)" \
" ALT Print" "screenshot timer 5 secs " "(grim)" \
" CTRL ALT Print" "screenshot timer 10 secs " "(grim)" \
" Esc" "screen lock" "(hyprlock)" \
" Shift Esc" "power-menu" "(wlogout)" \
" SHIFT F" "Fullscreen" "Toggles to full screen" \
" CTRL F" "Fake Fullscreen" "Toggles to fake full screen" \
" ALT L" "Toggle Dwindle | Master Layout" "Hyprland Layout" \
" SPACEBAR" "Toggle float" "single window" \
" ALT O" "Toggle Blur" "normal or less blur" \
" CTRL A" "Animations Menu" "Choose Animations via rofi" \
" CTRL ALT R" "Rofi Themes Menu v2" "Choose Rofi Themes via Theme Selector (modified)" \
" G" "Gamemode, all animations, notifcation, and containers OFF or ON" "toggle" \
" E" "Rofi Emoticons" "Emoticon" \
" H" "Launch this Quick Cheat Sheet" "" \