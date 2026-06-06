#!/usr/bin/env bash

dir="$HOME/.config/rofi/applaunch"
theme='my-style'

rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
