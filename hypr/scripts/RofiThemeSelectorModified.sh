#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# A modified version of Rofi-Theme-Selector, concentrating only on ~/.local and also, applying only 10 @themes in ~/.config/rofi/config.rasi
# as opposed to continous adding of //@theme

# This code is released in public domain by Dave Davenport <qball@gmpclient.org>

iconsDir="$HOME/.config/swaync/icons"


OS="linux"

ROFI=$(command -v rofi)
SED=$(command -v sed)
MKTEMP=$(command -v mktemp)
NOTIFY_SEND=$(command -v notify-send)

if [ -z "${SED}" ]
then
    echo "Did not find 'sed', script cannot continue."
    exit 1
fi
if [ -z "${MKTEMP}" ]
then
    echo "Did not find 'mktemp', script cannot continue."
    exit 1
fi
if [ -z "${ROFI}" ]
then
    echo "Did not find rofi, there is no point to continue."
    exit 1
fi
if [ -z "${NOTIFY_SEND}" ]
then
    echo "Did not find 'notify-send', notifications won't work."
fi

tmpConfigFile=$(${MKTEMP}).rasi
#rofi_theme_dir="${HOME}/.local/share/rofi/themes"
rofiConfigFile="${XDG_CONFIG_HOME:-${HOME}/.config}/rofi/config.rasi"

##
# Array with parts to the found themes.
# And array with the printable name.
##
declare -a themes
declare -a themeNames

##
# Function that tries to find all installed rofi themes.
# This fills in #themes array and formats a displayable string #themeNames
##
# Find themes in defined directories
find_themes() {
    directories=("$HOME/.local/share/rofi/themes" "$HOME/.config/rofi/themes")
    
    for TD in "${directories[@]}"; do
        if [ -d "$TD" ]; then
            echo "Checking themes in: $TD"
            for file in "$TD"/*.rasi; do
                if [ -f "$file" ] && [ ! -L "$file" ]; then
                    themes+=("$file")
                    themeNames+=("$(basename "${file%.*}")")
                else
                    echo "Skipping symlink: $file"
                fi
            done
        else
            echo "Directory does not exist: $TD"
        fi
    done
}

##
# Function to add or update theme in the config.rasi
##
add_theme_to_config() {
    local themeName="$1"
    local themePath

    # Determine the correct path for the theme
    if [[ -f "$HOME/.local/share/rofi/themes/$themeName.rasi" ]]; then
        themePath="$HOME/.local/share/rofi/themes/$themeName.rasi"
    elif [[ -f "$HOME/.config/rofi/themes/$themeName.rasi" ]]; then
        themePath="$HOME/.config/rofi/themes/$themeName.rasi"
    else
        echo "Theme not found: $themeName"
        return 1
    fi

    # Resolve symlinks if present
    if [[ -L "$themePath" ]]; then
        themePath=$(readlink -f "$themePath")
    fi

    # Convert path to use ~ for home directory
    themePathWithTilde="~${themePath#$HOME}"

    # Add or update @theme line in config
    if ! grep -q '^\s*@theme' "$rofiConfigFile"; then
        echo -e "\n\n@theme \"$themePathWithTilde\"" >> "$rofiConfigFile"
        echo "Added @theme \"$themePathWithTilde\" to $rofiConfigFile"
    else
        $SED -i "s/^\(\s*@theme.*\)/\/\/\1/" "$rofiConfigFile"
        echo -e "@theme \"$themePathWithTilde\"" >> "$rofiConfigFile"
        echo "Updated @theme line to $themePathWithTilde"
    fi

    # Limit the number of @theme lines to a maximum of 9
    maxLines=9
    totalLines=$(grep -c '^\s*//@theme' "$rofiConfigFile")

    if [ "$totalLines" -gt "$maxLines" ]; then
        excess=$((totalLines - maxLines))
        for i in $(seq 1 "$excess"); do
            $SED -i '0,/^\s*\/\/@theme/ { /^\s*\/\/@theme/ {d; q; }}' "$rofiConfigFile"
        done
        echo "Removed excess //@theme lines"
    fi
}

##
# Create a copy of rofi config
##
create_config_copy()
{
    ${ROFI} -dump-config > "${tmpConfigFile}"
    # remove theme entry.
    ${SED} -i 's/^\s*theme:\s\+".*"\s*;//g' "${tmpConfigFile}"
}

###
# Print the list out so it can be displayed by rofi.
##
create_theme_list()
{
    OLDIFS=${IFS}
    IFS='|'
    for themen in ${themeNames[@]}
    do
        echo "${themen}"
    done
    IFS=${OLDIFS}
}

##
# Thee indicate what entry is selected.
##
declare -i SELECTED

select_theme()
{
    local moreFlags=(-dmenu -format i -no-custom -p "Theme" -markup -config "${tmpConfigFile}" -i)
    moreFlags+=(-kb-custom-1 "Alt-a")
    moreFlags+=(-u 2,3 -a 4,5 )
    local CUR="default"
    while true
    do
        declare -i RTR
        declare -i RES
        local MESG="""You can preview themes by hitting <b>Enter</b>.
<b>Alt-a</b> to accept the new theme.
<b>Escape</b> to cancel
Current theme: <b>${CUR}</b>
<span weight=\"bold\" size=\"xx-small\">When setting a new theme this will override previous theme settings.
Please update your config file if you have local modifications.</span>"""
        themeFlags=
        if [ -n "${SELECTED}" ]
        then
            themeFlags="-theme ${themes[${SELECTED}]}"
        fi
        RES=$( create_theme_list | ${ROFI} ${themeFlags} ${moreFlags[@]} -cycle -selected-row "${SELECTED}" -mesg "${MESG}")
        RTR=$?
        if [ "${RTR}" = 10 ]
        then
            return 0;
        elif [ "${RTR}" = 1 ]
        then
            return 1;
        elif [ "${RTR}" = 65 ]
        then
            return 1;
        fi
        CUR=${themeNames[${RES}]}
        SELECTED=${RES}
    done
}

############################################################################################################
# Actual program execution
###########################################################################################################
##
# Find all themes
##
find_themes

##
# Do check if there are themes.
##
if [ ${#themes[@]} = 0 ]
then
    ${ROFI} -e "No themes found."
    exit 0
fi

##
# Create copy of config to play with in preview
##
create_config_copy

##
# Show the themes to user.
##
if select_theme && [ -n "${SELECTED}" ]
then
    # Apply the selected theme
    add_theme_to_config "${themeNames[${SELECTED}]}"

    # Send notification with the selected theme name
    selection="${themeNames[${SELECTED}]}"
    if [ -n "$NOTIFY_SEND" ]; then
        notify-send -u low -i "$iconsDir/ok.svg"  "Rofi Theme applied:" "$selection"
    fi
fi

##
# Remove temp. config.
##
rm -- "${tmpConfigFile}"
