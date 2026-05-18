#!/bin/sh

source "$CONFIG_DIR/variables.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

# Nerd Font glyphs (nf-fa-battery_*, nf-fa-bolt) as UTF-8 byte sequences
ICON_FULL=$(printf '\xef\x89\x80')        # U+F240
ICON_3Q=$(printf '\xef\x89\x81')          # U+F241
ICON_HALF=$(printf '\xef\x89\x82')        # U+F242
ICON_1Q=$(printf '\xef\x89\x83')          # U+F243
ICON_EMPTY=$(printf '\xef\x89\x84')       # U+F244
ICON_BOLT=$(printf '\xef\x83\xa7')        # U+F0E7

case ${PERCENTAGE} in
  9[0-9]|100) ICON=$ICON_FULL;  COLOR=$GREEN
  ;;
  [6-8][0-9]) ICON=$ICON_3Q;    COLOR=$GREEN
  ;;
  [3-5][0-9]) ICON=$ICON_HALF;  COLOR=$YELLOW
  ;;
  [1-2][0-9]) ICON=$ICON_1Q;    COLOR=$ORANGE
  ;;
  *)          ICON=$ICON_EMPTY; COLOR=$RED
esac

if [ -n "$CHARGING" ]; then
  ICON=$ICON_BOLT
  COLOR=$GREEN
fi

sketchybar --set $NAME icon="$ICON" icon.color=$COLOR label="${PERCENTAGE}%"
