#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

iDIR="$HOME/.config/swaync/icons"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 1
 	notify-send -e -u low -i "$iDIR/note.svg" " Less Blur"
else
	hyprctl keyword decoration:blur:size 5
	hyprctl keyword decoration:blur:passes 2
  	notify-send -e -u low -i "$iDIR/ok.svg" " Normal Blur"
fi
