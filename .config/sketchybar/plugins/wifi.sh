#!/usr/bin/env sh

SSID="$(ipconfig getsummary "$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')" | grep '  SSID : ' | awk -F ': ' '{print $2}')"

if [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Disconnected" icon=󱚼
else
  sketchybar --set $NAME label="$SSID" icon=
fi
