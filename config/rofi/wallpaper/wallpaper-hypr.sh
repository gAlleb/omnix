#!/usr/bin/env bash
# Wallpapers Path
CACHE_DIR="$HOME/.cache/omnix_wallpaper"
WALLPAPER_DIR="$HOME/.config/wallpaper"
THEMES_DIR="$HOME/.config/rofi/wallpaper/themes"
ROFI_DIR="$HOME/.config/rofi"
CURRENT_WALLPAPER_PATH_FILE="${CACHE_DIR}/current_wallpaper_path"

if [ ! -d "${CACHE_DIR}" ] ; then
    mkdir -p "${CACHE_DIR}"
fi

if [ ! -d ~/.config/dunst ] ; then
    mkdir -p ~/.config/dunst
fi 

# Create thumbnails for all wallpapers if they don't exist in the cache.
# This makes Rofi load much faster.
# Note: Requires 'imagemagick' to be installed.
find -L "${WALLPAPER_DIR}" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.webp \) | while read -r wallpaper_path; do
    # Get the relative path to maintain subdirectory structure in the cache
    relative_path="${wallpaper_path#${WALLPAPER_DIR}/}"
    thumbnail_path="${CACHE_DIR}/thumbnails/${relative_path%.*}.png"

    # Create the directory in the cache if it doesn't exist
    if [ ! -d "$(dirname "${thumbnail_path}")" ]; then
        mkdir -p "$(dirname "${thumbnail_path}")"
    fi

    # If the thumbnail doesn't exist, create it
    if [ ! -f "${thumbnail_path}" ]; then
        # Using magick to create a small thumbnail
        magick "${wallpaper_path}" -thumbnail '320x180>' "${thumbnail_path}"
    fi
done

# Retrieve image files as a list
PICS=($(find -L "${WALLPAPER_DIR}" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif  -o -iname \*.webp \) | sort ))

# Use date variable to increase randomness
randomNumber=$(( ($(date +%s) + RANDOM) + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"
randomChoice="[${#PICS[@]}] Random"

themeSwitchChoice="🎨 Switch Theme" # <-- ADD THIS LINE
# Rofi command
rofiCommand="rofi -show -dmenu -i -theme ${THEMES_DIR}/wallpaper-select.rasi"

# Execute command according the wallpaper manager
executeCommand() {
    # The selected wallpaper path is passed as the first argument ($1)
    local selected_wallpaper="$1"
    local relative_path="${selected_wallpaper#${WALLPAPER_DIR}/}"
    local selected_thumbnail_path="${CACHE_DIR}/thumbnails/${relative_path%.*}.png"
    mode_choice=$(echo -e "Dark Mode\0icon\x1f${THEMES_DIR}/black.png\nLight Mode\0icon\x1f${THEMES_DIR}/white.png" | rofi -dmenu -p "Select Mode" -theme "${ROFI_DIR}/menu-style-minimal.rasi")

    # If the user cancels the mode selection (e.g., presses Esc), exit gracefully.
    if [[ -z "$mode_choice" ]]; then
        exit 0
    fi

    # --- Determine the correct `wal` flag based on the choice ---
    local wal_flags=""
    if [ "$mode_choice" = "Light Mode" ]; then
        wal_flags="-l -i ${selected_wallpaper}"
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Light"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
        gsettings set org.gnome.desktop.interface icon-theme "WhiteSur-light"
        { mkdir -p ~/.config/Kvantum; printf "[General]\ntheme=WhiteSur-opaque\n" > ~/.config/Kvantum/kvantum.kvconfig; }
        omnix-theme-gnome-set-xorg "WhiteSur-Light" "WhiteSur-light" "0"
    else
        wal_flags="-i ${selected_wallpaper}"
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface icon-theme "WhiteSur-grey-dark"
        { mkdir -p ~/.config/Kvantum; printf "[General]\ntheme=WhiteSur-opaqueDark\n" > ~/.config/Kvantum/kvantum.kvconfig; }
        omnix-theme-gnome-set-xorg "WhiteSur-Dark" "WhiteSur-grey-dark" "1"
    fi

    wal -c

    # Generate the new color scheme using wal with the determined flag
    #wal ${wal_flags} -i ${selected_wallpaper}
    wal ${wal_flags} 

    # Update other applications
    awww img --transition-type any --transition-angle 45 "${selected_wallpaper}"
    pywalfox update
    omnix-theme-set-browser wal
    echo "\$wallpaper = ${selected_wallpaper}" > $CACHE_DIR/wallpaper-hyprland.conf
    pkill -SIGUSR2 waybar
    swaync-client -rs
    makoctl reload
    ln -sf ~/.cache/wal/dunstrc ~/.config/dunst/dunstrc
    dunstctl reload
    pkill -e --signal SIGKILL dunst
    wal-telegram --wal
    echo "\$wallpaper_thumbnail = $selected_thumbnail_path" > $CACHE_DIR/wallpaper_thumbnail
    echo "inputbar { background-image: url(\"$selected_thumbnail_path\", height); }" > $CACHE_DIR/wallpaper_thumbnail.rasi
#    $HOME/.config/nwg-dock-hyprland/reload.sh &
    $HOME/.config/swayosd/launch.sh &
    echo "${selected_wallpaper}" > "${CURRENT_WALLPAPER_PATH_FILE}"
    magick "${selected_wallpaper}" ~/.config/bg.jpg
}

# Show the images
menu() {

  printf "$themeSwitchChoice\n" 
  printf "$randomChoice\n"

  for i in "${!PICS[@]}"; do
  
    # If not *.gif, display with cached thumbnail
    if [[ ! "${PICS[$i]}" == *.gif ]]; then
      relative_path="${PICS[$i]#${WALLPAPER_DIR}/}"
      thumbnail_path="${CACHE_DIR}/thumbnails/${relative_path%.*}.png"
      printf "$(basename "${PICS[$i]}")\x00icon\x1f${thumbnail_path}\n"
    else
    # Displaying .gif to indicate animated images (without an icon)
      printf "$(basename "${PICS[$i]}")\n"
    fi
  done
}

# Execution
main() {
  choice=$(menu | ${rofiCommand})

  # No choice case
  if [[ -z $choice ]]; then
    exit 0
  fi

  # Random choice case
  if [ "$choice" = "$randomChoice" ]; then
    executeCommand "${randomPicture}"
    return 0
  

  # Theme Switcher choice case
  elif [ "$choice" = "$themeSwitchChoice" ]; then
    # Find the directory where this script is located
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    # Execute the other script and exit
    "$HOME/.config/rofi/wallpaper/wallpaper-switch-theme-hypr.sh"
    exit 0
  # --- END OF NEW SECTION ---

  fi
  # Find the selected file
  for file in "${PICS[@]}"; do
  # Getting the file by matching the full filename
    if [[ "$(basename "$file")" = "$choice" ]]; then
      selectedFile="$file"
      break
    fi
  done

  # Check the file and execute
  if [[ -n "$selectedFile" ]]; then
    executeCommand "${selectedFile}"
    return 0
  else
    echo "Image not found."
    exit 1
  fi

}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

main
