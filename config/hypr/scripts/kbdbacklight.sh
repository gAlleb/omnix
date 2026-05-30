#!/bin/bash

step=${2:-"10%"}
mode=$1

readonly KBDBACKLIGHT_LIMIT=100
readonly BAR_MAX_LENGTH=20

function get_kbdbacklight {
  kbdlight getp
}

function send_notification {
  kbdbacklight=$(get_kbdbacklight)
  bar=$(awk "BEGIN {printf \"%.2f\", $kbdbacklight/100}")

  # swayosd-client --custom-icon=preferences-desktop-keyboard --custom-progress-text="$kbdbacklight%" --custom-progress=${bar}
  swayosd-client --custom-icon=preferences-desktop-keyboard --custom-progress=${bar}

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
