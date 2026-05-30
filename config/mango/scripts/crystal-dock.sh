#!/bin/sh
pgrep -x crystal-dock > /dev/null && pkill -x crystal-dock || crystal-dock > /dev/null 2>&1
