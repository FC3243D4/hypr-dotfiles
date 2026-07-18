#!/usr/bin/env bash

topgrade && patch-grub

echo "checking code folder for writing permission"
TARGETS=(
    "/usr/share/code/resources/app/out/media"           # VSCode icons
    "/usr/lib/OneDriveGUI/resources/images"             # OneDriveGUI
    "/usr/share/nativmix/assets"                        # NativMix
    "/opt/ferdium-bin/assets/images/tray/linux"         # Ferdium tray
    "/usr/lib/localsend/data/flutter_assets/assets/img" # LocalSend
    "/usr/lib/streamcontroller/Assets/icons/hicolor"    # StreamController
    "$HOME/.local/share/Steam/public/"                  # Steam
    "/usr/share/pixmaps/"                               # generic pixmaps
)

for target in $TARGETS
do
    if [ -d $target ]; then
        # Check if any file inside is not writable
        if find "$target" -not -writable | grep -q .; then
            echo "Found non-writable files inside $target, fixing ownership..."
            sudo chown -R "$USER" "$target"
        else
            echo "Everything inside $target is already writable, nothing to do."
        fi
    fi
done

pkill -RTMIN+8 waybar
