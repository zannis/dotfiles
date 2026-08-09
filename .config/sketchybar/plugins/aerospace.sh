#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:$PATH"
export LC_ALL=en_US.UTF-8  # UTF-8 char classes/slicing for Claude title glyphs

# controller for all space.* chips: existence, focus highlight, dynamic labels.
# FOCUSED_WORKSPACE is set by the aerospace_workspace_change trigger; other
# invocations (front_app_switched, update_freq poll) query it themselves.
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
windows="$(aerospace list-windows --all --format '%{workspace}|%{window-id}|%{app-name}|%{window-title}')"
existing="$(aerospace list-workspaces --all)"

RED=0xffff5c5c     # Claude waiting on input
YELLOW=0xffe6c850  # Claude working
GREEN=0xff00dc82   # Claude idle, nothing pending
WHITE=0xffffffff

# Titles share one character budget so the chip row stays inside the bar no
# matter how many Claude sessions are live; per-title width shrinks as they add up.
TITLE_BUDGET=56
TITLE_MAX=22
TITLE_MIN=6
APPS_MAX=12

# Claude sessions per workspace as "ws<TAB>rank<TAB>count<TAB>title", where rank
# is 3 waiting / 2 busy / 1 idle — the worst state among that workspace's
# sessions, plus the title of the session that set it. The join is exact:
# aerospace's %{window-id} is kitty's platform_window_id, and a session's
# process-tree ancestor is the pid kitty launched in the owning window.
# Sessions with no owning kitty window (detached, `claude -p`) are ignored.
claude_by_workspace() {
  local sock socks=()
  for sock in "${TMPDIR%/}"/kitty.sock-*; do
    [ -S "$sock" ] && socks+=("$sock")
  done
  [ "${#socks[@]}" -eq 0 ] && return

  {
    ps -Ao pid=,ppid= | awk '{ print "p\t" $1 "\t" $2 }'
    for sock in "${socks[@]}"; do
      kitten @ --to "unix:$sock" ls 2>/dev/null |
        jq -r '.[] | .platform_window_id as $w | .tabs[].windows[]
               | ["k", $w, .pid, .title] | @tsv'
    done
    awk -F'|' '$3 == "kitty" { print "a\t" $1 "\t" $2 }' <<<"$windows"
    cat "$HOME"/.claude/sessions/*.json 2>/dev/null |
      jq -r 'select(.kind == "interactive") | ["s", .pid, .status] | @tsv'
  } | awk -F'\t' '
    $1 == "p" { parent[$2] = $3; next }
    $1 == "k" { owner[$3] = $2; wtitle[$3] = $4; next }
    $1 == "a" { space[$3] = $2; next }
    $1 == "s" { status[$2] = $3; next }
    END {
      for (pid in status) {
        p = pid
        for (i = 0; i < 24 && p != "" && !(p in owner); i++) p = parent[p]
        if (!(p in owner) || !(owner[p] in space)) continue
        s = space[owner[p]]
        rank = status[pid] == "waiting" ? 3 : (status[pid] == "busy" ? 2 : 1)
        total[s]++
        if (rank > best[s]) { best[s] = rank; title[s] = wtitle[p] }
      }
      for (s in total) printf "%s\t%d\t%d\t%s\n", s, best[s], total[s], title[s]
    }'
}

# app names in a workspace, collapsed to "first+N" when the joined list is too wide
apps_label() {
  local ws="$1" apps n joined
  apps="$(awk -F'|' -v ws="$ws" '$1 == ws {print tolower($3)}' <<<"$windows" \
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
claude_spaces="$(claude_by_workspace)"

for sid in "${sids[@]}"; do
  if [ "$sid" != "$focused" ] && ! grep -qx "$sid" <<<"$existing"; then
    kinds+=(hidden); hls+=(off); colors+=(""); glyphs+=(""); texts+=(""); extras+=(0)
    continue
  fi

  hl=off
  [ "$sid" = "$focused" ] && hl=on
  hls+=("$hl")

  state="$(awk -F'\t' -v ws="$sid" '$1 == ws { print; exit }' <<<"$claude_spaces")"
  if [ -n "$state" ]; then
    IFS=$'\t' read -r _ rank total t <<<"$state"
    case "$t" in
      ✳*|[⠀-⣿]*) t="${t:2}" ;;  # drop Claude's own status glyph, we draw our own
    esac
    case "$rank" in
      3) c=$RED;    g="○" ;;
      2) c=$YELLOW; g="●" ;;
      *) c=$GREEN;  g="○" ;;
    esac
    kinds+=(claude); colors+=("$c"); glyphs+=("$g"); texts+=("$t"); extras+=("$((total - 1))")
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
