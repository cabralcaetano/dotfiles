#!/bin/bash
case "$1" in
  up)   wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac

MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}')

if [ "$MUTED" -gt 0 ]; then
  ICON="audio-volume-muted"
  LABEL="Mudo"
  VOL=0
elif [ "$VOL" -gt 66 ]; then
  ICON="audio-volume-high"
  LABEL="$VOL%"
elif [ "$VOL" -gt 33 ]; then
  ICON="audio-volume-medium"
  LABEL="$VOL%"
else
  ICON="audio-volume-low"
  LABEL="$VOL%"
fi

notify-send \
  -h string:x-canonical-private-synchronous:volume \
  -h int:value:"$VOL" \
  -i "$ICON" \
  -t 1500 \
  "Volume" "$LABEL"
