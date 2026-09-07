#!/usr/bin/env bash
# RofiWidthScale.sh — shared helper to size rofi windows to the focused
# monitor's aspect ratio. Not meant to be run directly; source it:
#
#   source "$scriptsDir/RofiWidthScale.sh"
#   rofiWidth=$(rofi_scaled_width)
#   rofi ... -theme-str "window { width: ${rofiWidth}%; }"
#
# For scripts whose theme also uses a multi-column listview (currently
# only KeyBinds.sh):
#
#   read -r rofiWidth rofiColumns <<< "$(rofi_scaled_width_and_columns)"
#   rofi ... -theme-str "window { width: ${rofiWidth}%; } listview { columns: ${rofiColumns}; }"
#
# 16:9 is the anchor: 75% width (2 columns where applicable).
#   - narrower/taller than 16:9 -> interpolate 75% up to 85% at 4:3
#   - wider than 16:9           -> interpolate 75% down to 65% at 32:9
#     (columns, where used: 3 for moderately wide, 4 past ~3.0 ratio)

rofi_monitor_ratio() {
    local monW monH
    IFS=' ' read -r monW monH < <(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width) \(.height)"')
    [[ -z "$monW" || -z "$monH" ]] && { monW=1920; monH=1080; }
    awk -v w="$monW" -v h="$monH" 'BEGIN { printf "%.3f", w / h }'
}

rofi_scaled_width() {
    local ratio; ratio=$(rofi_monitor_ratio)
    awk -v r="$ratio" 'BEGIN{
        refRatio = 1.778; refWidth = 75

        if (r <= refRatio) {
            minRatio = 1.333; maxWidth = 85
            rr = r; if (rr < minRatio) rr = minRatio
            width = refWidth + (refRatio - rr) / (refRatio - minRatio) * (maxWidth - refWidth)
        } else {
            maxRatio = 3.556; minWidth = 65
            rr = r; if (rr > maxRatio) rr = maxRatio
            width = refWidth - (rr - refRatio) / (maxRatio - refRatio) * (refWidth - minWidth)
        }
        printf "%d", width
    }'
}

rofi_scaled_width_and_columns() {
    local ratio; ratio=$(rofi_monitor_ratio)
    awk -v r="$ratio" 'BEGIN{
        refRatio = 1.778; refWidth = 75

        if (r <= refRatio) {
            minRatio = 1.333; maxWidth = 85
            rr = r; if (rr < minRatio) rr = minRatio
            width = refWidth + (refRatio - rr) / (refRatio - minRatio) * (maxWidth - refWidth)
            columns = 2
        } else {
            maxRatio = 3.556; minWidth = 65
            rr = r; if (rr > maxRatio) rr = maxRatio
            width = refWidth - (rr - refRatio) / (maxRatio - refRatio) * (refWidth - minWidth)
            columns = (r > 3.0) ? 4 : 3
        }
        printf "%d %d", width, columns
    }'
}

# rofi's listview fills column-major (fills one whole column of `lines`
# items before starting the next), so a short list with a high column
# count leaves later columns completely empty. This caps the column
# count to how many columns the item count can actually fill.
#   rofi_cap_columns <columns> <item_count> <lines>
rofi_cap_columns() {
    local columns=$1 itemCount=$2 lines=$3
    local maxUseful=$(( (itemCount + lines - 1) / lines ))
    (( maxUseful < 1 )) && maxUseful=1
    (( columns > maxUseful )) && columns=$maxUseful
    echo "$columns"
}