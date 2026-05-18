#!/usr/bin/env sh

source "$CONFIG_DIR/variables.sh"

# Nerd Font: nf-fa-wifi (U+F1EB), nf-md-wifi_strength_off_outline (U+F16BC)
ICON_ON=$(printf '\xef\x87\xab')
ICON_OFF=$(printf '\xf3\xb1\x9a\xbc')

SSID="$(system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1;print $0 | "tr -d ':'";exit}')"

if [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Disconnected" icon="$ICON_OFF" icon.color=$RED
else
  sketchybar --set $NAME label="$SSID" icon="$ICON_ON" icon.color=$CYAN
fi
