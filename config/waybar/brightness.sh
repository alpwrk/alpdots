#!/usr/bin/env bash
# Optimistic per-monitor brightness for Waybar via DDC/CI.
#
# Why this design: DDC writes/reads take ~80-160ms and would make the label lag
# behind the scroll wheel. So the label is driven from a tiny cache and the
# actual panel write happens in a detached background applier that coalesces
# rapid scrolls to the latest value.
#
# Waybar does not pass WAYBAR_OUTPUT_NAME to on-scroll-* handlers, so each
# monitor runs its own bar entry with the output hardwired:
#
#   brightness.sh <output>            -> print cached value as JSON (seeds once)
#   brightness.sh <output> up|down    -> step cache by 5%, wake bar, silent
#   brightness.sh <output> _apply     -> detached worker, push cache to panel
#
# State lives in $XDG_RUNTIME_DIR/waybar-brightness/.

set -euo pipefail

OUTPUT="${1:-}"
ACTION="${2:-}"
STEP=5
ICON="󰖙"

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness"
MAP="$STATE/map"
PCT="$STATE/$OUTPUT.pct"
APPLIED="$STATE/$OUTPUT.applied"
MAXF="$STATE/$OUTPUT.max"
LOCK="$STATE/$OUTPUT.lock"

mkdir -p "$STATE"

out_json() {
  printf '{"text":"%s %s","tooltip":"%s"}\n' "$ICON" "$1" "$2"
}

read_int() { cat "$1" 2>/dev/null || printf ''; }

write_int() { printf '%s\n' "$2" > "$1.tmp.$$" && mv -f "$1.tmp.$$" "$1"; }

clamp() { local v=$1; (( v < 0 )) && v=0; (( v > 100 )) && v=100; printf '%s' "$v"; }

if [[ -z "$OUTPUT" ]]; then
  out_json "--" "no output argument"
  exit 0
fi

signal_for() {
  case "$1" in
    HDMI-A-1) printf '9' ;;
    DP-1)     printf '11' ;;
    *)        printf '9' ;;
  esac
}

load_map() {
  ddcutil detect --brief 2>/dev/null | awk '
    /I2C bus:/        { bus = $3; sub(/.*\/dev\/i2c-/, "", bus) }
    /DRM connector:/  { conn = $3; sub(/^card[0-9]+-/, "", conn);
                        if (conn != "" && bus != "") print conn, bus }
  ' > "$MAP"
}

bus_for() {
  local bus
  bus="$(awk -v o="$1" '$1 == o { print $2; exit }' "$MAP" 2>/dev/null || true)"
  if [[ -z "$bus" ]]; then
    load_map
    bus="$(awk -v o="$1" '$1 == o { print $2; exit }' "$MAP" 2>/dev/null || true)"
  fi
  printf '%s' "$bus"
}

# Read the panel once and populate the cache. Only runs when cache is cold.
seed() {
  local bus cur max
  bus="$(bus_for "$OUTPUT")"
  [[ -z "$bus" ]] && return 1
  read -r cur max < <(ddcutil --bus "$bus" --noverify getvcp 10 --terse 2>/dev/null | awk '{print $4, $5}')
  if [[ -z "${cur:-}" || -z "${max:-}" ]]; then
    rm -f "$MAP"
    bus="$(bus_for "$OUTPUT")"
    [[ -z "$bus" ]] && return 1
    read -r cur max < <(ddcutil --bus "$bus" --noverify getvcp 10 --terse 2>/dev/null | awk '{print $4, $5}')
  fi
  [[ -z "${cur:-}" || -z "${max:-}" || "$max" -eq 0 ]] && return 1
  write_int "$MAXF" "$max"
  write_int "$PCT" "$(( (cur * 100 + max / 2) / max ))"
  write_int "$APPLIED" "$(read_int "$PCT")"
  return 0
}

ensure_cache() {
  [[ -s "$PCT" && -s "$MAXF" ]] && return 0
  seed
}

# Detached worker: push the cached value to the panel until it matches what we
# last applied. Coalesces scroll bursts because it always reads the newest pct.
run_applier() {
  local out="$1" pct max applied bus target
  trap 'rm -f "$LOCK"' EXIT
  printf '%s\n' "$$" > "$LOCK"
  max="$(read_int "$MAXF")"
  [[ -z "$max" || "$max" -eq 0 ]] && exit 0
  bus="$(bus_for "$out")"
  [[ -z "$bus" ]] && exit 0
  while :; do
    pct="$(read_int "$PCT")"
    applied="$(read_int "$APPLIED")"
    [[ -z "$pct" ]] && exit 0
    [[ "$pct" == "$applied" ]] && exit 0
    target=$(( (pct * max + 50) / 100 ))
    ddcutil --bus "$bus" --noverify setvcp 10 "$target" >/dev/null 2>&1 || true
    write_int "$APPLIED" "$pct"
  done
}

case "$ACTION" in
  _apply)
    run_applier "$OUTPUT"
    exit 0
    ;;

  up|down)
    ensure_cache 2>/dev/null || true
    cur="$(read_int "$PCT")"
    [[ -z "$cur" ]] && exit 0
    if [[ "$ACTION" == "up" ]]; then
      new="$(clamp $(( cur + STEP )))"
    else
      new="$(clamp $(( cur - STEP )))"
    fi
    write_int "$PCT" "$new"
    # Start the applier only if one is not already running for this output.
    if [[ -s "$LOCK" ]] && kill -0 "$(read_int "$LOCK")" 2>/dev/null; then
      :
    else
      setsid "$0" "$OUTPUT" _apply </dev/null >/dev/null 2>&1 &
    fi
    pkill -RTMIN+"$(signal_for "$OUTPUT")" -x waybar 2>/dev/null || true
    exit 0
    ;;
esac

# Display path: cache only, never touch the panel (fast).
ensure_cache 2>/dev/null || { out_json "--" "$OUTPUT: DDC unavailable"; exit 0; }
pct="$(read_int "$PCT")"
[[ -z "$pct" ]] && { out_json "--" "$OUTPUT: no value"; exit 0; }
out_json "${pct}%" "$OUTPUT brightness: ${pct}%"
