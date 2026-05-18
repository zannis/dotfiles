#!/bin/sh

source "$CONFIG_DIR/variables.sh"

PAGE=$(sysctl -n hw.pagesize)
TOTAL=$(sysctl -n hw.memsize)

# Activity Monitor's "Memory Used" = App Memory + Wired + Compressed
#   App Memory ≈ anonymous - purgeable
eval "$(vm_stat | awk -v page="$PAGE" -v total="$TOTAL" '
  /Pages wired down/             { wired=$4+0 }
  /Pages purgeable/              { purgeable=$3+0 }
  /Anonymous pages/              { anon=$3+0 }
  /Pages occupied by compressor/ { comp=$5+0 }
  END {
    used = (anon - purgeable + wired + comp) * page
    pct  = int(used * 100 / total + 0.5)
    gb   = used / 1073741824
    printf "PERCENT=%d USED_GB=%.1f", pct, gb
  }
')"

case ${PERCENT} in
  9[0-9]|100|[1-9][0-9][0-9]) COLOR=$RED
  ;;
  [7-8][0-9]) COLOR=$ORANGE
  ;;
  [5-6][0-9]) COLOR=$YELLOW
  ;;
  *) COLOR=$GREEN
esac

# Nerd Font: nf-fa-microchip (U+F2DB)
ICON=$(printf '\xef\x8b\x9b')

sketchybar --set $NAME icon="$ICON" \
                       icon.color=$COLOR \
                       label="${USED_GB}G"
