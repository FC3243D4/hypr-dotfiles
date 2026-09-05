#!/usr/bin/env bash

for i in {0..3}; do
  if [ -f /sys/class/power_supply/BAT$i/capacity ]; then
    batteryLevel=$(cat /sys/class/power_supply/BAT$i/status)
    batteryCapacity=$(cat /sys/class/power_supply/BAT$i/capacity)
    echo "Battery: $batteryCapacity% ($batteryLevel)"
  fi
done
