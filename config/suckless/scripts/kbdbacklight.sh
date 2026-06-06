#!/usr/bin/env bash

step=${2:-"10%"}
mode=$1

readonly KBDBACKLIGHT_LIMIT=100
readonly BAR_MAX_LENGTH=20

function get_kbdbacklight {
  kbdlight getp
}

function send_notification {
  kbdbacklight=$(get_kbdbacklight)
  bar=$(seq -s "󰝤" $(($kbdbacklight/5)) | sed 's/[0-9]//g')

  dunstify "$kbdbacklight%""   ""${bar:0:$BAR_MAX_LENGTH}" -i "/usr/share/icons/Faba/48x48/notifications/notification-keyboard-brightness.svg" -t 2000  -u low --replace=1000
}

if [ "$mode" == "up" ]; then
  if [ $(get_kbdbacklight) -lt $KBDBACKLIGHT_LIMIT ]; then
    kbdlight up "$step"
  fi
fi

if [ "$mode" == "down" ]; then
    kbdlight down "$step"
fi

send_notification 
