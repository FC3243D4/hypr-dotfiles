#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script to manage UserConfigs and UserConfigsBak

hyprConfigsDir="$HOME/.config/hypr"
userConfigs="$hyprConfigsDir/UserConfigs"
userConfigsBackup="$hyprConfigsDir/UserConfigsBak"

if [ -d "$userConfigs" ] && [ ! -d "$userConfigsBackup" ]; then
  echo "Moving UserConfigs to UserConfigsBak..."
  mv "$userConfigs" "$userConfigsBackup"
  echo "Done. Your UserConfigs are now in UserConfigsBak."
elif [ ! -d "$userConfigs" ] && [ -d "$userConfigsBackup" ]; then
  echo "Moving UserConfigsBak to UserConfigs..."
  mv "$userConfigsBackup" "$userConfigs"
  echo "Done. Your backup has been restored to UserConfigs."
elif [ -d "$userConfigs" ] && [ -d "$userConfigsBackup" ]; then
  echo "Both UserConfigs and UserConfigsBak exist."
  echo "Please choose what to do:"
  PS3="Enter your choice: "
  select option in "Backup current UserConfigs (move to UserConfigsBak)" "Restore backup (move UserConfigsBak to UserConfigs)" "Swap them" "Do nothing"; do
    case $REPLY in
    1)
      echo "Backing up UserConfigs..."
      rm -rf "$userConfigsBackup"
      mv "$userConfigs" "$userConfigsBackup"
      echo "Done. UserConfigs moved to UserConfigsBak."
      break
      ;;
    2)
      echo "Restoring backup..."
      rm -rf "$userConfigs"
      mv "$userConfigsBackup" "$userConfigs"
      echo "Done. UserConfigsBak moved to UserConfigs."
      break
      ;;
    3)
      echo "Swapping..."
      mv "$userConfigs" "$hyprConfigsDir/UserConfigs.tmp"
      mv "$userConfigsBackup" "$userConfigs"
      mv "$hyprConfigsDir/UserConfigs.tmp" "$userConfigsBackup"
      echo "Done. UserConfigs and UserConfigsBak have been swapped."
      break
      ;;
    4)
      echo "No changes made."
      break
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
    esac
  done
else
  echo "Neither UserConfigs nor UserConfigsBak directory found. Nothing to do."
fi
