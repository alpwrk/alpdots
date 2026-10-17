#!/usr/bin/env bash
# Installs alpdots: packages (Arch-based distros) + symlinks configs into ~/.config.
# Existing configs are moved to <name>.bak-<timestamp> first.
set -euo pipefail

cat <<'BANNER'
         __          __      __
  ____ _/ /___  ____/ /___  / /______
 / __ `/ / __ \/ __  / __ \/ __/ ___/
/ /_/ / / /_/ / /_/ / /_/ / /_(__  )
\__,_/_/ .___/\__,_/\____/\__/____/
      /_/

BANNER

DOTS="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d_%H%M%S)"

PKGS=(
  swayfx swaybg waybar rofi mako wlogout swaylock-effects ghostty zsh
  grim slurp wayfreeze wl-clipboard libnotify brightnessctl playerctl wireplumber
  polkit-gnome pavucontrol blueman network-manager-applet ddcutil
  python-gobject gtk4 gtk4-layer-shell
  adw-gtk-theme breeze-icons capitaine-cursors noto-fonts
  xdg-desktop-portal-gtk xdg-desktop-portal-wlr
  oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting
  fastfetch yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide
  ttf-jetbrains-mono-nerd ttf-bigblueterminal-nerd
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
link "$DOTS/home/.zshrc" "$HOME/.zshrc"
link "$DOTS/gtk/gtk-3.0/settings.ini" "$CONFIG/gtk-3.0/settings.ini"
link "$DOTS/gtk/gtk-4.0/settings.ini" "$CONFIG/gtk-4.0/settings.ini"

# Dark mode for GTK/libadwaita apps, and for Qt apps through the GTK portal.
# The settings.ini files above cover the same for apps that don't read gsettings.
if command -v gsettings >/dev/null; then
  gs() { gsettings set org.gnome.desktop.interface "$@" || true; }
  gs color-scheme prefer-dark
  gs gtk-theme adw-gtk3-dark
  gs icon-theme breeze-dark
  gs cursor-theme capitaine-cursors
  gs cursor-size 24
  gs font-name 'Noto Sans 10'
  echo "theme: dark mode set"
fi

# Laptop = a system battery (scope Device would be e.g. a wireless mouse).
# Puts the battery module at the far right of waybar via the gitignored local.jsonc.
is_laptop() {
  local ps
  for ps in /sys/class/power_supply/*; do
    [[ -r "$ps/type" && "$(<"$ps/type")" == Battery ]] || continue
    [[ "$(cat "$ps/scope" 2>/dev/null)" == Device ]] && continue
    return 0
  done
  return 1
}

LOCAL_WAYBAR="$DOTS/config/waybar/local.jsonc"
if is_laptop; then
  if [[ -e "$LOCAL_WAYBAR" ]]; then
    echo "laptop: $LOCAL_WAYBAR already exists, leaving it alone"
  else
    cat > "$LOCAL_WAYBAR" <<'JSON'
// Written by install.sh because this machine has a battery. Not tracked by git.
{
  "group/laptop": { "orientation": "inherit", "modules": ["battery"] }
}
JSON
    echo "laptop: battery module added to waybar"
  fi
fi

# Initial wallpaper for bgswitch, the sway config reads it from here
CACHE="$HOME/.cache/bgswitch"
if [[ ! -e "$CACHE/current" ]]; then
  mkdir -p "$CACHE"
  ln -sfn "$DOTS/config/sway/wallpaper/fogwoods.jpg" "$CACHE/current"
fi

# Make zsh the login shell if it isn't already (chsh asks for your password)
ZSH="$(command -v zsh || true)"
if [[ -z "$ZSH" ]]; then
  echo "zsh not found, keeping your current shell" >&2
elif [[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" != zsh ]]; then
  chsh -s "$ZSH" && echo "shell: switched to zsh (takes effect on next login)"
fi

mkdir -p "$HOME/Pictures/Screenshots"
echo "Done. Log into sway (or press Super+Shift+C if you're already in it)."
