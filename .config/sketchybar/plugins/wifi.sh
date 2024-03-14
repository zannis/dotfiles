#!/usr/bin/env sh

SSID="$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}' | xargs networksetup -getairportnetwork | sed "s/Current Wi-Fi Network: //")"

if [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Disconnected" icon=󱚼
else
  sketchybar --set $NAME label="$SSID" icon=
fi
