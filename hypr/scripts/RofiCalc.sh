#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# /* Calculator (using qalculate) and rofi */
# /* Submitted by: https://github.com/JosephArmas */

rofiTheme="$HOME/.config/rofi/config-calc.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# main function

while true; do
    result=$(
        rofi -i -dmenu \
            -config $rofiTheme \
            -mesg "$result      =    $calcResult"
    )

    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -n "$result" ]; then
        calcResult=$(qalc -t "$result")
        echo "$calcResult" | wl-copy
    fi
done
