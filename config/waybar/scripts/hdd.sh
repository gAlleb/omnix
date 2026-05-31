#!/usr/bin/env bash

hdd_percent="$(df -h | grep ' /$' | awk '{print $5}')"

icon=""

printf "%s %s\n" "$icon" "$hdd_percent"
