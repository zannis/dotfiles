#!/usr/bin/env sh

SSID="$(system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1;print $0 | "tr -d ':'";exit}')"

if [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Disconnected" icon=󱚼
else
  sketchybar --set $NAME label="$SSID" icon=
fi
