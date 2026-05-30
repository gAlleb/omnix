#!/usr/bin/env bash

# Paths (should match your main wallpaper script)
CACHE_DIR="$HOME/.cache/omnix_wallpaper"
WALLPAPER_DIR="$HOME/.config/wallpaper"
THEMES_DIR="$HOME/.config/rofi/wallpaper/themes"
ROFI_DIR="$HOME/.config/rofi"
CURRENT_WALLPAPER_PATH_FILE="${CACHE_DIR}/current_wallpaper_path"

# --- Main Logic ---

# 1. Check if a current wallpaper has been set before
if [ ! -f "${CURRENT_WALLPAPER_PATH_FILE}" ]; then
    rofi -e "No current wallpaper set. Please run the wallpaper picker first."
    exit 1
fi

# 2. Read the path of the current wallpaper
current_wallpaper=$(cat "${CURRENT_WALLPAPER_PATH_FILE}")

# 3. Check if the saved path is empty or the file doesn't exist anymore
if [ -z "${current_wallpaper}" ] || [ ! -f "${current_wallpaper}" ]; then
    rofi -e "Saved wallpaper not found. Please run the wallpaper picker again."
    exit 1
fi

# 4. Show the Rofi menu for Light/Dark mode selection
mode_choice=$(echo -e "Dark Mode\0icon\x1f${THEMES_DIR}/black.png\nLight Mode\0icon\x1f${THEMES_DIR}/white.png" | rofi -dmenu -p "Select Mode" -theme "${ROFI_DIR}/menu-style-minimal.rasi")

# 5. Exit if the user cancelled
if [[ -z "$mode_choice" ]]; then
    exit 0
fi

# 6. Determine the correct `wal` flag based on the choice
local wal_flags=""
if [ "$mode_choice" = "Light Mode" ]; then
    wal_flags="-l -i ${current_wallpaper}"
    kvantummanager --set WhiteSur-opaque
    omnix-theme-gnome-set-xorg "WhiteSur-Light" "WhiteSur-light" "0"
else
    wal_flags="-i ${current_wallpaper}"
    kvantummanager --set WhiteSur-opaqueDark
    omnix-theme-gnome-set-xorg "WhiteSur-Dark" "WhiteSur-grey-dark" "1"
fi

wal -c

# Generate the new color scheme using wal with the determined flag
#wal ${wal_flags} -i ${selected_wallpaper}
wal ${wal_flags} 

xrdb -merge ~/.Xresources
xrdb -merge $HOME/.cache/wal/colors-dwm-xresources
xdotool key alt+shift+F5
pkill -SIGUSR1 dwmblocks
pywalfox update
omnix-theme-set-browser wal
ln -sf ~/.cache/wal/dunstrc ~/.config/dunst/dunstrc 
dunstctl reload
pkill -e --signal SIGKILL dunst

exit 0
