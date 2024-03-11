#!/usr/bin/env sh

CURRENT_WIFI="$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}' | xargs networksetup -getairportnetwork | sed "s/Current Wi-Fi Network: //")"
SSID="$(echo "$CURRENT_WIFI" | grep -o "SSID: .*" | sed 's/^SSID: //')"
CURR_TX="$(echo "$CURRENT_WIFI" | grep -o "lastTxRate: .*" | sed 's/^lastTxRate: //')"

if [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Disconnected" icon=睊
else
  sketchybar --set $NAME label="$SSID (${CURR_TX}Mbps)" icon=直
fi
