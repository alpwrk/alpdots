# alpdots

A minimal monochrome Sway rice: SwayFX blur, a transparent Waybar, a mono Rofi launcher, Mako notifications, Wlogout and Swaylock.

| Component    | Config                  |
|--------------|-------------------------|
| WM           | SwayFX                  |
| Bar          | Waybar                  |
| Launcher     | Rofi                    |
| Notifications| Mako                    |
| Power menu   | Wlogout                 |
| Lockscreen   | Swaylock-effects        |
| Terminal     | Ghostty                 |
| Font         | JetBrainsMono Nerd Font |

## Install

For Arch-based distros (Arch, CachyOS, EndeavourOS, …). You need an AUR helper (`yay` or `paru`).

```sh
git clone https://github.com/alpwrk/alpdots.git ~/alpdots
cd ~/alpdots
./install.sh
```

The script installs the packages and symlinks every folder in `config/` into `~/.config`. Any configs you already have get renamed to `<name>.bak-<timestamp>`, so nothing is lost.

If you're on a different distro or want to install the packages yourself:

```sh
./install.sh --no-deps
```

### Packages

All programs this rice uses, in one command (`swayfx`, `wlogout` and `swaylock-effects` are in the AUR):

```sh
yay -S --needed swayfx swaybg waybar rofi mako wlogout swaylock-effects ghostty grim slurp wl-clipboard brightnessctl playerctl wireplumber polkit-gnome pavucontrol blueman network-manager-applet ttf-jetbrains-mono-nerd
```

Then log into Sway. If you're already in Sway, press `Super + Shift + C`.

### Update

Since the configs are symlinks, updating is just:

```sh
cd ~/alpdots && git pull
```

## Keybinds

| Keys                         | Action                          |
|------------------------------|---------------------------------|
| `Super + Enter`              | Terminal (Ghostty)              |
| `Alt + Space`                | App launcher (Rofi)             |
| `Super + W` / `Super + Shift + Q` | Close window               |
| `Super + Esc`                | Power menu (Wlogout)            |
| `Super + H/J/K/L` or arrows  | Move focus                      |
| `Super + Shift + H/J/K/L`    | Move window                     |
| `Super + 1-0`                | Switch workspace                |
| `Super + Shift + 1-0`        | Move window to workspace        |
| `Super + F`                  | Fullscreen                      |
| `Super + Shift + Space`      | Toggle floating                 |
| `Super + R`                  | Resize mode                     |
| `Super + AltGr + ,`          | Toggle Waybar                   |
| `Super + Shift + C`          | Reload Sway and Waybar          |
| `Super + Shift + E`          | Exit Sway                       |
| `Print`                      | Screenshot area to clipboard    |
| `Shift + Print`              | Screenshot area to `~/Pictures/Screenshots` |
| `Ctrl + Alt + Ü / Ö / Ä`     | Play-pause / previous / next    |

Hover the right edge of the bar, just left of the volume, to slide out the tray, do-not-disturb toggle, network and bluetooth.

## Customize

- **Keyboard layout:** the config uses `de`. Change `xkb_layout` in `config/sway/config`.
- **Monitors:** Sway picks your monitor's preferred mode. To set a refresh rate, add e.g. `output DP-1 mode 1920x1080@144Hz` (list outputs with `swaymsg -t get_outputs`).
- **Wallpaper:** drop an image into `config/sway/wallpaper/` and update the `output * bg` line in `config/sway/config` (and `image=` in `config/swaylock/config` for the lockscreen).
- **SwayFX effects:** blur, shadows and rounded corners only apply after a full Sway restart (log out and back in), not on reload.

## Uninstall

```sh
for d in ~/alpdots/config/*; do rm ~/.config/$(basename "$d"); done
```

Then rename your `.bak-*` folders back if you want your old configs.
