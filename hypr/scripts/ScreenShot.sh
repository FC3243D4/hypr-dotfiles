#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Screenshots scripts

# variables
time=$(date "+%d-%b_%H-%M-%S")
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

iconsDir="$HOME/.config/swaync/icons"
scriptsDir="$HOME/.config/hypr/scripts"

activeWindowClass=$(hyprctl -j activewindow | jq -r '(.class)')
activeWindowFile="Screenshot_${time}_${activeWindowClass}.png"
activeWindowPath="${dir}/${activeWindowFile}"

notifyCmdBase="notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notifyCmdShot="${notifyCmdBase} -i ${iconsDir}/picture.svg "
notifyCmdShot_win="${notifyCmdBase} -i ${iconsDir}/picture.svg "
notifyCmdNot="notify-send -u low -i ${iconsDir}/note.svg "

# notify and view screenshot
notify_view() {
    if [[ "$1" == "active" ]]; then
        if [[ -e "${activeWindowPath}" ]]; then
			"${scriptsDir}/Sounds.sh" --screenshot        
            resp=$(timeout 5 ${notifyCmdShot_win} " Screenshot of:" " ${activeWindowClass} Saved.")
            case "$resp" in
				action1)
					xdg-open "${activeWindowPath}" &
					;;
				action2)
					rm "${activeWindowPath}" &
					;;
			esac
        else
            ${notifyCmdNot} " Screenshot of:" " ${activeWindowClass} NOT Saved."
            "${scriptsDir}/Sounds.sh" --error
        fi

    elif [[ "$1" == "swappy" ]]; then
		"${scriptsDir}/Sounds.sh" --screenshot
		resp=$(${notifyCmdShot} " Screenshot:" " Captured by Swappy")
		case "$resp" in
			action1)
				swappy -f - <"$tmpfile"
				;;
			action2)
				rm "$tmpfile"
				;;
		esac

    else
        local checkFile="${dir}/${file}"
        if [[ -e "$checkFile" ]]; then
            "${scriptsDir}/Sounds.sh" --screenshot
            resp=$(timeout 5 ${notifyCmdShot} " Screenshot" " Saved")
			case "$resp" in
				action1)
					xdg-open "${checkFile}" &
					;;
				action2)
					rm "${checkFile}" &
					;;
			esac
        else
            ${notifyCmdNot} " Screenshot" " NOT Saved"
            "${scriptsDir}/Sounds.sh" --error
        fi
    fi
}

# countdown
countdown() {
	for sec in $(seq $1 -1 1); do
		notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$iconsDir"/timer.svg  " Taking shot" " in: $sec secs"
		sleep 1
	done
}

# take shots
shotnow() {
	cd ${dir} && grim - | tee "$file" | wl-copy
	sleep 2
	notify_view
}

shot5() {
	countdown '5'
	sleep 1 && cd ${dir} && grim - | tee "$file" | wl-copy
	sleep 1
	notify_view
}

shot10() {
	countdown '10'
	sleep 1 && cd ${dir} && grim - | tee "$file" | wl-copy
	notify_view
}

shotwin() {
	w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
	w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
	cd ${dir} && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
	notify_view
}

shotarea() {
	tmpfile=$(mktemp)
	grim -g "$(slurp)" - >"$tmpfile"

  # Copy with saving
	if [[ -s "$tmpfile" ]]; then
		wl-copy <"$tmpfile"
		mv "$tmpfile" "$dir/$file"
	fi
	notify_view
}

shotactive() {
    activeWindowClass=$(hyprctl -j activewindow | jq -r '(.class)')
    activeWindowFile="Screenshot_${time}_${activeWindowClass}.png"
    activeWindowPath="${dir}/${activeWindowFile}"

    hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${activeWindowPath}"
	sleep 1
    notify_view "active"
}

shotswappy() {
	tmpfile=$(mktemp)
	grim -g "$(slurp)" - >"$tmpfile" 

  # Copy without saving
  if [[ -s "$tmpfile" ]]; then
		wl-copy <"$tmpfile"
    notify_view "swappy"
  fi
}

if [[ ! -d "$dir" ]]; then
	mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
	shotnow
elif [[ "$1" == "--in5" ]]; then
	shot5
elif [[ "$1" == "--in10" ]]; then
	shot10
elif [[ "$1" == "--win" ]]; then
	shotwin
elif [[ "$1" == "--area" ]]; then
	shotarea
elif [[ "$1" == "--active" ]]; then
	shotactive
elif [[ "$1" == "--swappy" ]]; then
	shotswappy
else
	echo -e "Available Options : --now --in5 --in10 --win --area --active --swappy"
fi

exit 0
