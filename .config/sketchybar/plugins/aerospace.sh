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

# Titles share one character budget so the chip row stays inside the bar no
# matter how many Claude sessions are live; per-title width shrinks as they add up.
TITLE_BUDGET=56
TITLE_MAX=22
TITLE_MIN=6
APPS_MAX=12

# Claude sessions in a workspace → "color<TAB>glyph<TAB>title<TAB>extra", empty if none
claude_state() {
  local ws="$1" working=0 waiting=0 title="" t
  while IFS= read -r t; do
    case "$t" in
      ✳*)     waiting=$((waiting + 1)) ;;
      [⠀-⣿]*) working=$((working + 1)) ;;
      *) continue ;;
    esac
    [ -z "$title" ] && title="${t:2}"
  done < <(awk -F'|' -v ws="$ws" '$1 == ws && $2 == "kitty" { sub(/^[^|]*\|[^|]*\|/, ""); print }' <<<"$windows")

  local total=$((working + waiting))
  [ "$total" -eq 0 ] && return
  local glyph="●" color=$GREEN
  if [ "$waiting" -gt 0 ]; then glyph="○"; color=$YELLOW; fi
  printf '%s\t%s\t%s\t%s\n' "$color" "$glyph" "$title" "$((total - 1))"
}

# app names in a workspace, collapsed to "first+N" when the joined list is too wide
apps_label() {
  local ws="$1" apps n joined
  apps="$(awk -F'|' -v ws="$ws" '$1 == ws {print tolower($2)}' <<<"$windows" \
          | awk '{print $1}' | sort -u)"
  [ -z "$apps" ] && return
  n="$(wc -l <<<"$apps" | tr -d ' ')"
  joined="$(paste -sd+ - <<<"$apps")"
  if [ "${#joined}" -gt "$APPS_MAX" ]; then
    joined="$(head -1 <<<"$apps")"
    [ "$n" -gt 1 ] && joined="$joined+$((n - 1))"
  fi
  printf '%s\n' "$joined"
}

# pass 1: decide what each chip shows, and count the chips competing for title width
sids=(1 2 3 4 5 6 7 8 9 10 brave chat)
kinds=(); hls=(); colors=(); glyphs=(); texts=(); extras=()
claude_n=0

for sid in "${sids[@]}"; do
  if [ "$sid" != "$focused" ] && ! grep -qx "$sid" <<<"$existing"; then
    kinds+=(hidden); hls+=(off); colors+=(""); glyphs+=(""); texts+=(""); extras+=(0)
    continue
  fi

  hl=off
  [ "$sid" = "$focused" ] && hl=on
  hls+=("$hl")

  state="$(claude_state "$sid")"
  if [ -n "$state" ]; then
    IFS=$'\t' read -r c g t e <<<"$state"
    kinds+=(claude); colors+=("$c"); glyphs+=("$g"); texts+=("$t"); extras+=("$e")
    claude_n=$((claude_n + 1))
    continue
  fi

  case "$sid" in
    brave|chat)  # name already says what lives there
      kinds+=(bare); colors+=(""); glyphs+=(""); texts+=(""); extras+=(0)
      ;;
    *)
      apps="$(apps_label "$sid")"
      if [ -n "$apps" ]; then
        kinds+=(apps); colors+=($WHITE); glyphs+=(""); texts+=("$apps"); extras+=(0)
      else
        kinds+=(bare); colors+=(""); glyphs+=(""); texts+=(""); extras+=(0)
      fi
      ;;
  esac
done

budget=$TITLE_MAX
if [ "$claude_n" -gt 0 ]; then
  budget=$((TITLE_BUDGET / claude_n))
  [ "$budget" -gt "$TITLE_MAX" ] && budget=$TITLE_MAX
  [ "$budget" -lt "$TITLE_MIN" ] && budget=$TITLE_MIN
fi

# pass 2: truncate to the shared budget and push
args=()
for i in "${!sids[@]}"; do
  sid="${sids[$i]}"
  case "${kinds[$i]}" in
    hidden)
      args+=(--set "space.$sid" drawing=off)
      ;;
    bare)
      args+=(--set "space.$sid" drawing=on background.drawing="${hls[$i]}" label.drawing=off)
      ;;
    apps)
      args+=(--set "space.$sid" drawing=on background.drawing="${hls[$i]}" \
             label="${texts[$i]}" label.color="${colors[$i]}" label.drawing=on)
      ;;
    claude)
      title="${texts[$i]}"
      extra="${extras[$i]}"
      avail=$budget
      [ "$extra" -gt 0 ] && avail=$((budget - 3))
      [ "$avail" -lt "$TITLE_MIN" ] && avail=$TITLE_MIN
      if [ "${#title}" -gt "$avail" ]; then
        title="${title:0:$avail}…"
      fi
      [ "$extra" -gt 0 ] && title="$title +$extra"
      args+=(--set "space.$sid" drawing=on background.drawing="${hls[$i]}" \
             label="${glyphs[$i]} $title" label.color="${colors[$i]}" label.drawing=on)
      ;;
  esac
done

sketchybar "${args[@]}"
