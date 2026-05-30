#!/bin/sh

# browser and mpv should never display if paused.
if [ -z "$MUSIC_PLAYING_PLAYERS" ]; then
	# if MUSIC_PLAYING_PLAYERS is not set, use the default players
	MUSIC_PLAYING_PLAYERS="firefox brave chromium spotify de.haeckerfelix.Shortwave strawberry mpd mpv"
fi

# Flag to check if we've displayed anything playing
PLAYING_FOUND=0

for PLAYER in $MUSIC_PLAYING_PLAYERS; do
# if the player is not playing, continue to the next player, until we find one that is playing
	if [ "$(playerctl --player=$PLAYER status 2>/dev/null)" = "Playing" ]; then
		PLAYING_FOUND=1
    CURRENT_PLAYER="$PLAYER"
		break # Exit the loop as we found a playing track
	fi
done

# If no playing track was found, then display what's paused in mpd
if [ "$PLAYING_FOUND" -eq 0 ]; then
    # Check if mpd is actually paused or stopped
    MPD_STATUS=$(playerctl --player=mpd status 2>/dev/null)
    if [ "$MPD_STATUS" = "Paused" ] || [ "$MPD_STATUS" = "Stopped" ]; then
        CURRENT_PLAYER="mpd"
    fi
fi

radio() {
    MPV_STATUS=$(playerctl --player=mpv status 2>/dev/null)
    SHORTWAVE=$(playerctl --player=de.haeckerfelix.Shortwave status 2>/dev/null)
    if [ "$MPV_STATUS" = "Playing" ]; then
       pkill -f "mpv --volume"    
       notify-send "Stopping radio" "You have quit radio. 🎶"
    elif [ "$SHORTWAVE" = "Playing" ]; then
       shortwave
    elif [ "$(playerctl --player $CURRENT_PLAYER status)" = "Playing" ]; then
       playerctl --player $CURRENT_PLAYER play-pause
    else
       playerctl --player mpd play-pause
    fi
}

radio
