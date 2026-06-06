#!/use/bin/env bash

step=${2:-"10%"}
mode=$1

readonly BRIGHTNESS_LIMIT=100
readonly BAR_MAX_LENGTH=20

function get_brightness {
  # current brightness
  curr_brightness=$(cat /sys/class/backlight/*/brightness)

  # max_brightness
  max_brightness=$(cat /sys/class/backlight/*/max_brightness)

  # brightness percentage
brightness_per=$((100 * curr_brightness / max_brightness))
  
  echo "$brightness_per"
}

get_icon() {
  #"/usr/share/icons/Faba/48x48/notifications/notification-display-brightness.svg"
  iDIR="/home/$USER/.config/suckless/icons/"
	current=$(get_brightness)
	if   [ "$current" -le "20" ]; then
		echo "$iDIR/brightness-20.png"
    return
	elif [ "$current" -le "40" ]; then
		echo "$iDIR/brightness-40.png"
    return
	elif [ "$current" -le "60" ]; then
		echo "$iDIR/brightness-60.png"
    return
	elif [ "$current" -le "80" ]; then
		echo "$iDIR/brightness-80.png"
    return
	else
		echo "$iDIR/brightness-100.png"
    return
	fi
}

function send_notification {
  brightness=$(get_brightness)
  bar=$(seq -s "󰝤" $(($brightness/5)) | sed 's/[0-9]//g')

  dunstify "$brightness%""   ""${bar:0:$BAR_MAX_LENGTH}" -i $(get_icon) -t 2000  -u low --replace=1000
}

if [ "$mode" == "up" ]; then
  if [ $(get_brightness) -lt $BRIGHTNESS_LIMIT ]; then
    brightnessctl set +"$step"
  fi
fi

if [ "$mode" == "down" ]; then
    brightnessctl set "$step"-
fi

send_notification && kill -44 $(pidof dwmblocks)
