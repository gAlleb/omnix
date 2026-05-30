#!/usr/bin/env bash

    THEMES_DIR=$HOME/.config/rofi/wallpaper/themes
    CACHE_DIR=$HOME/.cache/omnix_wallpaper 
    SPECIFIC_WAYPAPER_CACHE_DIR=$HOME/.cache/waypaper
    WALLPAPER_DIR="$HOME/.config/wallpaper"
    CURRENT_WALLPAPER_PATH_FILE="${CACHE_DIR}/current_wallpaper_path"
   
    selected_wallpaper=$1
    relative_path="${selected_wallpaper#${WALLPAPER_DIR}/}"
    selected_thumbnail_path="${CACHE_DIR}/thumbnails/${relative_path%.*}.png"
    
    mode_choice=$(echo -e "Dark Mode\0icon\x1f${THEMES_DIR}/black.png\nLight Mode\0icon\x1f${THEMES_DIR}/white.png" | rofi -dmenu -p "Select Mode" -theme "${THEMES_DIR}/dark-light-mode-select.rasi")

    if [[ -z $mode_choice ]]; then
        exit 0
    fi

    # --- Determine the correct `wal` flag based on the choice ---
    local wal_flags=""
    if [ "$mode_choice" = "Light Mode" ]; then
        wal_flags="-l -i ${selected_wallpaper}"
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Light"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
        gsettings set org.gnome.desktop.interface icon-theme "WhiteSur-light"
        kvantummanager --set WhiteSur-opaque
    else
        wal_flags="-i ${selected_wallpaper}"
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface icon-theme "WhiteSur-grey-dark"
        kvantummanager --set WhiteSur-opaqueDark
    fi

    wal -c

    # Generate the new color scheme using wal with the determined flag
    #wal ${wal_flags} -i ${selected_wallpaper}
    wal ${wal_flags} 
    
    swww img --transition-type any --transition-angle 45 "${selected_wallpaper}"
    pywalfox update
    echo "\$wallpaper = ${selected_wallpaper}" > $CACHE_DIR/wallpaper-hyprland.conf
    pkill -SIGUSR2 waybar
    swaync-client -rs
    echo "\$wallpaper_thumbnail = $selected_thumbnail_path" > $CACHE_DIR/wallpaper_thumbnail
    echo "inputbar { background-image: url(\"$selected_thumbnail_path\", height); }" > $CACHE_DIR/wallpaper_thumbnail.rasi
    $HOME/.config/nwg-dock-hyprland/reload.sh &
    $HOME/.config/swayosd/launch.sh &
    echo "${selected_wallpaper}" > "${CURRENT_WALLPAPER_PATH_FILE}"
    magick "${selected_wallpaper}" ~/.config/bg.jpg

