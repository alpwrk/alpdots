#!/usr/bin/env bash
# Installs alpdots: packages (Arch-based distros) + symlinks configs into ~/.config.
# Existing configs are moved to <name>.bak-<timestamp> first.
set -euo pipefail

DOTS="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d_%H%M%S)"

PKGS=(
  swayfx swaybg waybar rofi mako wlogout swaylock-effects ghostty
  grim slurp wl-clipboard brightnessctl playerctl wireplumber
  polkit-gnome pavucontrol blueman network-manager-applet
  ttf-jetbrains-mono-nerd
)

if [[ "${1:-}" != "--no-deps" ]]; then
  if command -v paru >/dev/null; then
    paru -S --needed "${PKGS[@]}"
  elif command -v yay >/dev/null; then
    yay -S --needed "${PKGS[@]}"
  else
    echo "No AUR helper (yay/paru) found. Install yay or run with --no-deps." >&2
    exit 1
  fi
fi

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]] && [[ "$(readlink -f "$dst")" != "$src" ]]; then
    mv "$dst" "$dst.bak-$STAMP"
    echo "backup: $dst -> $dst.bak-$STAMP"
  fi
  ln -sfn "$src" "$dst"
  echo "linked: $dst"
}

for dir in "$DOTS"/config/*; do
  link "$dir" "$CONFIG/$(basename "$dir")"
done

mkdir -p "$HOME/Pictures/Screenshots"
echo "Done. Log into sway (or press Super+Shift+C if you're already in it)."
