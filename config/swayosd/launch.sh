#!/bin/bash
pkill -x swayosd-server
setsid swayosd-server > /dev/null 2>&1
