#!/bin/bash

# Get metadata from playerctl
ART_URL=$(playerctl metadata mpris:artUrl 2> /dev/null)
COVER_PATH="/tmp/waybar-cover.png"

# If no art, use a default image or keep it blank
if [ -z "$ART_URL" ]; then
    echo "{\"text\": \"No Art\", \"tooltip\": \"No Art\"}"
    # Optionally echo a blank path or default icon
    exit
fi

# If it's a URL, download it
if [[ $ART_URL == http* ]]; then
    curl -s "$ART_URL" --output "$COVER_PATH"
else
    # If it's a local file (file://), copy it
    cp "${ART_URL/file:\/\//}" "$COVER_PATH"
fi

if [ -z "$MUSIC_PLAYING_PLAYERS" ]; then
	# if MUSIC_PLAYING_PLAYERS is not set, use the default players
	MUSIC_PLAYING_PLAYERS="firefox brave chromium spotify de.haeckerfelix.Shortwave strawberry mpd mpv"
fi 
for PLAYER in $MUSIC_PLAYING_PLAYERS; do
# if the player is not playing, continue to the next player, until we find one that is playing
if [ "$(playerctl --player=$PLAYER status 2>/dev/null)" = "Playing" ]; then
		PLAYING_FOUND=1
    CURRENT_PLAYER="$PLAYER"
		break # Exit the loop as we found a playing track
	fi
done
if [ "$PLAYING_FOUND" -eq 0 ]; then
    CURRENT_PLAYER="mpd"
fi
            # Use CURRENT_PLAYER for notify-send
            if [ -n "$CURRENT_PLAYER" ]; then # Check if a player was identified
                TITLE_FORMAT="{{ title }}"
                ARTIST_FORMAT="{{ artist }}"
                ALBUM_FORMAT="{{ album }}"

                NOTIF_TITLE="$(playerctl metadata --player "$CURRENT_PLAYER" --format "$TITLE_FORMAT")"
                NOTIF_BODY="Artist: $(playerctl metadata --player "$CURRENT_PLAYER" --format "$ARTIST_FORMAT")\nAlbum: $(playerctl metadata --player "$CURRENT_PLAYER" --format "$ALBUM_FORMAT")"

                notify-send \
                    --icon=media-playback-start \
                    -i "$COVER_PATH" \
                    "$NOTIF_TITLE" \
                    "$NOTIF_BODY"
            else
                # Fallback if no player was found (e.g., nothing playing/paused)
                notify-send "Music" "No player active."
            fi
