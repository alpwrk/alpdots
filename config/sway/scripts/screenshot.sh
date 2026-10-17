#!/bin/sh
# Freeze screen → select area → save to ~/Pictures/Screenshots + copy to clipboard
# grim excludes the cursor by default (no -c), so it never shows up in screenshots.

if [ "$1" != --capture ] && command -v wayfreeze >/dev/null; then
    # wayfreeze overlays a still frame, then runs the capture stage on top of it
    exec wayfreeze --hide-cursor --after-freeze-cmd "$0 --capture"
fi

geom=$(slurp)
status=$?
[ -n "$geom" ] && [ $status -eq 0 ] && {
    name=$(date +%Y-%m-%d_%H-%M-%S).png
    file="$HOME/Pictures/Screenshots/$name"
    grim -g "$geom" "$file"
}
pkill -x wayfreeze                 # unfreeze (also on Esc)
[ -n "$file" ] || exit 0           # Esc → cancel, no notification

wl-copy < "$file"
action=$(notify-send -i "$file" -A default="Open in GIMP" --wait "Screenshot" "Saved & copied: $name")
[ "$action" = default ] && exec gimp "$file"
