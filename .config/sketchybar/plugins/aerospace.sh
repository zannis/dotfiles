#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:$PATH"
export LC_ALL=en_US.UTF-8  # UTF-8 char classes/slicing for Claude title glyphs

# controller for all space.* chips: existence, focus highlight, dynamic labels.
# FOCUSED_WORKSPACE is set by the aerospace_workspace_change trigger; other
# invocations (front_app_switched, update_freq poll) query it themselves.
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
windows="$(aerospace list-windows --all --format '%{workspace}|%{app-name}|%{window-title}')"
existing="$(aerospace list-workspaces --all)"

GREEN=0xff00dc82   # Claude working (braille spinner in title)
YELLOW=0xffe6c850  # Claude waiting/idle (✳ in title)
WHITE=0xffffffff

# Claude sessions in a workspace → "GLYPH title[…] [+N]" + color, empty if none
claude_label() {
  local ws="$1" working=0 waiting=0 first="" t title
  while IFS= read -r t; do
    case "$t" in
      ✳*)     waiting=$((waiting + 1)) ;;
      [⠀-⣿]*) working=$((working + 1)) ;;
      *) continue ;;
    esac
    if [ -z "$first" ]; then
      title="${t:2}"
      first="${title:0:22}"
      [ "${#title}" -gt 22 ] && first="${first}…"
    fi
  done < <(awk -F'|' -v ws="$ws" '$1 == ws && $2 == "kitty" { sub(/^[^|]*\|[^|]*\|/, ""); print }' <<<"$windows")

  local total=$((working + waiting))
  [ "$total" -eq 0 ] && return
  local glyph="●" color=$GREEN
  if [ "$waiting" -gt 0 ]; then glyph="○"; color=$YELLOW; fi
  [ "$total" -gt 1 ] && first="$first +$((total - 1))"
  printf '%s\n%s %s\n' "$color" "$glyph" "$first"
}

args=()
for sid in 1 2 3 4 5 6 7 8 9 10 brave chat; do
  if [ "$sid" = "$focused" ] || grep -qx "$sid" <<<"$existing"; then
    hl=off
    [ "$sid" = "$focused" ] && hl=on

    claude="$(claude_label "$sid")"
    if [ -n "$claude" ]; then
      color="${claude%%$'\n'*}"
      label="${claude#*$'\n'}"
      args+=(--set "space.$sid" drawing=on background.drawing=$hl label="$label" label.color="$color" label.drawing=on)
      continue
    fi

    case "$sid" in
      brave|chat)
        # name already says what lives there
        args+=(--set "space.$sid" drawing=on background.drawing=$hl label.drawing=off)
        ;;
      *)
        apps="$(awk -F'|' -v ws="$sid" '$1 == ws {print tolower($2)}' <<<"$windows" \
                | awk '{print $1}' | sort -u | paste -sd+ -)"
        if [ -n "$apps" ]; then
          args+=(--set "space.$sid" drawing=on background.drawing=$hl label="$apps" label.color=$WHITE label.drawing=on)
        else
          args+=(--set "space.$sid" drawing=on background.drawing=$hl label.drawing=off)
        fi
        ;;
    esac
  else
    args+=(--set "space.$sid" drawing=off)
  fi
done

sketchybar "${args[@]}"
