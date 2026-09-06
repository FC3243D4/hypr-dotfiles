#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

iconsDir="$HOME/.config/swaync/icons"

state=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${state}" == "2" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 1
 	notify-send -e -u low -i "$iconsDir/note.svg" " Less Blur"
else
	hyprctl keyword decoration:blur:size 5
	hyprctl keyword decoration:blur:passes 2
  	notify-send -e -u low -i "$iconsDir/ok.svg" " Normal Blur"
fi
