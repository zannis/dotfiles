#!/bin/sh

source "$CONFIG_DIR/variables.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME=$INFO

  case $VOLUME in
    [6-9][0-9]|100) ICON="󰕾"
    ;;
    [3-5][0-9]) ICON="󰖀"
    ;;
    [1-9]|[1-2][0-9]) ICON="󰕿"
    ;;
    *) ICON="󰖁"
  esac

  if [ "$VOLUME" = "0" ]; then
    COLOR=$COMMENT
  else
    COLOR=$MAGENTA
  fi

  sketchybar --set $NAME icon="$ICON" icon.color=$COLOR label="$VOLUME%"
fi
