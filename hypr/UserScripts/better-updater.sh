#!/usr/bin/env bash

kitty -T update bash -c "topgrade && patch-grub"
pkill -RTMIN+8 waybar
