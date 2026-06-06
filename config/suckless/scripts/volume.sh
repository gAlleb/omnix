#!/usr/bin/env bash

# [DEPENDENCIES]

# dunst (https://github.com/dunst-project/dunst)
# pulseaudio (https://github.com/pulseaudio/pulseaudio)
# faba-icon-theme (https://github.com/snwh/faba-icon-theme)


# [USAGE]

# [value] - optional argument
# volume.sh up [25%]
# volume.sh down [25%]
# /volume.sh mute
# /volume.sh unmute
# /volume.sh toggle

step=${2:-"5%"}
mode=$1

readonly VOLUME_LIMIT=150
readonly BAR_MAX_LENGTH=20

function get_volume {
  pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -1
}

function is_muted {
  pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes'
}

# function get_icon {
#   dir="/usr/share/icons/Faba/48x48/notifications/"
# 
#   if is_muted; then
#     echo "$dir"notification-audio-volume-muted.svg
#     return
#   fi
# 
#   if [ $volume == "0" ]; then
#     echo "$dir"notification-audio-volume-muted.svg
#     return
#   fi
# 
#   if [ $volume -lt "25" ]; then
#     echo "$dir"notification-audio-volume-low.svg
#     return
#   fi
# 
#   if [ $volume -lt "50" ]; then
#     echo "$dir"notification-audio-volume-low.svg
#     return
#   fi
# 
#   if [ $volume -lt "75" ]; then
#     echo "$dir"notification-audio-volume-medium.svg
#     return
#   else
#     echo "$dir"notification-audio-volume-high.svg
#   fi
# }
function get_icon {
  dir="/home/$USER/.config/suckless/icons/"

  if is_muted; then
    echo "$dir"volume-mute.png
    return
  fi

  if [ $volume == "0" ]; then
    echo "$dir"volume-mute.png

    return
  fi

  if [ $volume -lt "25" ]; then
    echo "$dir"volume-down.png
    return
  fi

  if [ $volume -lt "50" ]; then
    echo "$dir"volume-down.png
    return
  fi

  if [ $volume -lt "75" ]; then
    echo "$dir"volume-mid.png
    return
  else
    echo "$dir"volume-up.png
  fi
}

function send_notification {
  volume=$(get_volume)
  bar=$(seq -s "󰝤" $(($volume/5)) | sed 's/[0-9]//g')

  if is_muted; then
    dunstify -i $(get_icon) -t 2000 -u low "Mute" --replace=1000
  else
    dunstify "$volume%""  ""${bar:0:$BAR_MAX_LENGTH}" -i $(get_icon) -u low -t 2000 --replace=1000
  fi
}

if [ "$mode" == "up" ]; then
  if [ $(get_volume) -lt $VOLUME_LIMIT ] && ! is_muted; then
    pactl set-sink-volume @DEFAULT_SINK@ +"$step"
  fi
fi

if [ "$mode" == "down" ]; then
  if ! is_muted; then
    pactl set-sink-volume @DEFAULT_SINK@ -"$step"
  fi
fi

if [ "$mode" == "mute" ]; then
  pactl set-sink-mute @DEFAULT_SINK@ yes
fi

if [ "$mode" == "unmute" ]; then
  pactl set-sink-mute @DEFAULT_SINK@ no
fi

if [ "$mode" == "toggle" ]; then
  if is_muted; then
    pactl set-sink-mute @DEFAULT_SINK@ no
  else
    pactl set-sink-mute @DEFAULT_SINK@ yes
  fi
fi

send_notification && kill -48 $(pidof dwmblocks)

