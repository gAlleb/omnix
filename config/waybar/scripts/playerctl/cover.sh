#!/bin/bash
# Get metadata from playerctl
if [ -z "$MUSIC_PLAYING_PLAYERS" ]; then
	# if MUSIC_PLAYING_PLAYERS is not set, use the default players
	MUSIC_PLAYING_PLAYERS="brave chromium firefox spotify de.haeckerfelix.Shortwave strawberry audacious mpd mpv"
fi

# Flag to check if we've displayed anything playing
PLAYING_FOUND=0

for PLAYER in $MUSIC_PLAYING_PLAYERS; do 

	if [ "$(playerctl --player=$PLAYER status 2>/dev/null)" = "Playing" ]; then

    ART_URL=$(playerctl metadata --player=$PLAYER mpris:artUrl 2> /dev/null)
    COVER_PATH="/tmp/waybar-cover.png"

    # If it's a URL, download it
    if [[ $ART_URL == http* ]]; then
        curl -s "$ART_URL" --output "$COVER_PATH"
    else
        # If it's a local file (file://), copy it
        cp "${ART_URL/file:\/\//}" "$COVER_PATH"
    fi

     # If no art, use a default image or keep it blank
     if [ -z "$ART_URL" ]; then
        echo "{\"text\": \"No Art\", \"tooltip\": \"No Art\"}"
        # Optionally echo a blank path or default icon
        exit
     fi

    PLAYING_FOUND=1
    CURRENT_PLAYER="$PLAYER"
    echo "$COVER_PATH"
    break
  fi
done

# If no playing track was found, then display what's paused in mpd
if [ "$PLAYING_FOUND" -eq 0 ]; then
    # Check if mpd is actually paused or stopped
    MPD_STATUS=$(playerctl --player=mpd status 2>/dev/null)
    if [ "$MPD_STATUS" = "Paused" ] || [ "$MPD_STATUS" = "Stopped" ]; then
       ART_URL=$(playerctl metadata --player=mpd mpris:artUrl 2> /dev/null)
       COVER_PATH="/tmp/waybar-cover.png"
       CURRENT_PLAYER="mpd"
       # If it's a URL, download it
       if [[ $ART_URL == http* ]]; then
          curl -s "$ART_URL" --output "$COVER_PATH"
      else
          # If it's a local file (file://), copy it
          cp "${ART_URL/file:\/\//}" "$COVER_PATH"
       fi
       echo "$COVER_PATH"
    fi
fi

