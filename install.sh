#!/bin/sh
# Installs alpdots: packages (Arch-based distros or FreeBSD) + symlinks configs
# into ~/.config. Existing configs are moved to <name>.bak-<timestamp> first.
# Plain POSIX sh, so it also runs where bash isn't installed (FreeBSD base).
set -eu

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
OS="$(uname -s)"

PKGS_ARCH="
  swayfx swaybg waybar rofi dmenu mako wlogout swaylock-effects ghostty zsh
  grim slurp wayfreeze wl-clipboard libnotify brightnessctl playerctl wireplumber
  polkit-gnome pavucontrol blueman network-manager-applet ddcutil
  python-gobject gtk4 gtk4-layer-shell
  adw-gtk-theme breeze-icons capitaine-cursors noto-fonts
  xdg-desktop-portal-gtk xdg-desktop-portal-wlr
  oh-my-posh-bin zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
  fastfetch yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide
  ttf-jetbrains-mono-nerd ttf-bigblueterminal-nerd
"

# Same set for FreeBSD's pkg. Names that don't exist in the repo are skipped
# with a warning instead of failing the whole install. Linux-only tools
# (ddcutil, brightnessctl, wayfreeze, blueman) are left out on purpose.
PKGS_FREEBSD="
  swayfx swaybg waybar rofi-wayland dmenu mako wlogout swaylock-effects ghostty zsh
  grim slurp wl-clipboard libnotify playerctl pipewire wireplumber
  polkit-gnome pavucontrol networkmgr
  py311-gobject3 gtk4 gtk4-layer-shell glib
  adw-gtk3 kf6-breeze-icons capitaine-cursors noto-basic
  xdg-desktop-portal-gtk xdg-desktop-portal-wlr
  oh-my-posh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
  fastfetch yazi ffmpeg 7-zip jq poppler-utils fd-find ripgrep fzf zoxide
  nerd-fonts
"

install_arch() {
  if command -v paru >/dev/null; then
    # shellcheck disable=SC2086 # word splitting is the point here
    paru -S --needed $PKGS_ARCH
  elif command -v yay >/dev/null; then
    # shellcheck disable=SC2086
    yay -S --needed $PKGS_ARCH
  else
    echo "No AUR helper (yay/paru) found. Install yay or run with --no-deps." >&2
    exit 1
  fi
}

install_freebsd() {
  if [ "$(id -u)" -eq 0 ]; then
    asroot=""
  elif command -v sudo >/dev/null; then
    asroot="sudo"
  elif command -v doas >/dev/null; then
    asroot="doas"
  else
    echo "Need root for pkg: install sudo or doas, or run with --no-deps." >&2
    exit 1
  fi

  $asroot pkg update
  found="" missing=""
  for p in $PKGS_FREEBSD; do
    if pkg rquery %n "$p" 2>/dev/null | grep -qx "$p"; then
      found="$found $p"
    else
      missing="$missing $p"
    fi
  done
  # shellcheck disable=SC2086
  [ -n "$found" ] && $asroot pkg install -y $found
  if [ -n "$missing" ]; then
    echo "pkg: not available, skipped:$missing" >&2
  fi
}

if [ "${1:-}" != "--no-deps" ]; then
  case "$OS" in
    Linux)
      if command -v pacman >/dev/null; then
        install_arch
      else
        echo "Only Arch-based distros are supported for package install. Run with --no-deps." >&2
        exit 1
      fi
      ;;
    FreeBSD) install_freebsd ;;
    *)
      echo "No package install for $OS. Install the packages yourself and run with --no-deps." >&2
      exit 1
      ;;
  esac
fi

link() {
  src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if { [ -e "$dst" ] || [ -L "$dst" ]; } && [ "$(realpath "$dst" 2>/dev/null)" != "$src" ]; then
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

# Laptop = a system battery (scope Device on Linux would be e.g. a wireless mouse).
# Puts the battery module at the far right of waybar via the gitignored local.jsonc.
is_laptop() {
  if [ "$OS" = FreeBSD ]; then
    units="$(sysctl -n hw.acpi.battery.units 2>/dev/null || echo 0)"
    [ "${units:-0}" -gt 0 ]
    return
  fi
  for ps in /sys/class/power_supply/*; do
    [ -r "$ps/type" ] && [ "$(cat "$ps/type")" = Battery ] || continue
    [ "$(cat "$ps/scope" 2>/dev/null)" = Device ] && continue
    return 0
  done
  return 1
}

LOCAL_WAYBAR="$DOTS/config/waybar/local.jsonc"
if is_laptop; then
  # Older installs wrote a modules-right list there, which the per-output bars
  # now override, so the battery vanished. Replace those (with a backup).
  if [ -e "$LOCAL_WAYBAR" ] && ! grep -q '"group/laptop"' "$LOCAL_WAYBAR"; then
    mv "$LOCAL_WAYBAR" "$LOCAL_WAYBAR.bak-$STAMP"
    echo "backup: $LOCAL_WAYBAR -> $LOCAL_WAYBAR.bak-$STAMP (outdated format)"
  fi
  if [ -e "$LOCAL_WAYBAR" ]; then
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

# Default waybar colors (half-transparent black). bgswitch's color row
# (AltGr+#, then Down) overwrites this file, so it's not tracked by git.
ACCENT="$DOTS/config/waybar/accent.css"
if [ ! -e "$ACCENT" ]; then
  cat > "$ACCENT" <<'CSS'
/* Default waybar colors from install.sh, bgswitch overwrites this file. */
@define-color background rgba(0, 0, 0, 0.5);
@define-color foreground #ffffff;
@define-color inverted #000000;
CSS
  echo "waybar: default colors written"
fi

# Initial wallpaper for bgswitch, the sway config reads it from here
CACHE="$HOME/.cache/bgswitch"
if [ ! -e "$CACHE/current" ]; then
  mkdir -p "$CACHE"
  ln -sfn "$DOTS/config/sway/wallpaper/fogwoods.jpg" "$CACHE/current"
fi

# Make zsh the login shell if it isn't already (chsh asks for your password)
ZSH="$(command -v zsh || true)"
if [ -z "$ZSH" ]; then
  echo "zsh not found, keeping your current shell" >&2
elif [ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" != zsh ]; then
  chsh -s "$ZSH" && echo "shell: switched to zsh (takes effect on next login)"
fi

mkdir -p "$HOME/Pictures/Screenshots"

if [ "$OS" = FreeBSD ]; then
  cat <<'NOTE'

FreeBSD: sway needs seatd and dbus running and you in the video group:
  sudo sysrc seatd_enable=YES dbus_enable=YES
  sudo service seatd start && sudo service dbus start
  sudo pw groupmod video -m "$USER"
NOTE
fi

echo "Done. Log into sway (or press Super+Shift+C if you're already in it)."
