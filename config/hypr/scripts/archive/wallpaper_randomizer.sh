#!/bin/bash

WALLPAPERS_DIR=~/.config/wallpaper

echo "Randomizing wallpaper"
random_wallpaper=$(find "$WALLPAPERS_DIR" -type f | shuf -n 1)

sh $HOME/.config/hypr/scripts/waypaper_helper.sh $random_wallpaper

