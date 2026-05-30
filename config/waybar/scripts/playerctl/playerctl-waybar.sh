#!/bin/sh

# playerctl loop ensures that when a track is skipped in the music player itself, it still updates on bar
pgrep -f omnix-bar-playerctl-loop >/dev/null 2>&1 || omnix-bar-playerctl-loop >/dev/null 2>&1 &

# priority is: if browser or mpv are playing, they will display. otherwise, mpd displays, playing or paused.
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
    if [ "$PLAYER" = "brave" ]; then
      ICON="󰖟 "
      META="{{ trunc(title,30) }}"
    elif [ "$PLAYER" = "mpv" ]; then
      ICON=" "
      META="{{ trunc(title,30) }}"
    else
		  ICON=" "
      META="{{ artist }} - {{ title }}" 
    fi
		echo "$ICON" $(playerctl metadata --player $PLAYER --format "$META")
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
        ICON=" "
        META="{{ artist }} - {{ title }}" 
        echo "$ICON" $(playerctl metadata --player mpd --format "$META")
        CURRENT_PLAYER="mpd"
    fi
fi


