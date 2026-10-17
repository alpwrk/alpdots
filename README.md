# alpdots

A minimal monochrome Sway rice: borderless SwayFX windows with blur, a transparent Waybar, a mono Rofi launcher, Mako notifications, Wlogout and Swaylock.

| Component    | Config                  |
|--------------|-------------------------|
| WM           | SwayFX                  |
| Bar          | Waybar                  |
| Launcher     | Rofi                    |
| Notifications| Mako                    |
| Power menu   | Wlogout                 |
| Lockscreen   | Swaylock-effects        |
| Terminal     | Ghostty                 |
| Shell        | zsh + oh-my-zsh         |
| File manager | Yazi                    |
| Fetch        | Fastfetch               |
| Wallpaper    | bgswitch (GTK4 overlay) |
| Font         | BigBlueTerm Nerd Font (bar, terminal), JetBrainsMono Nerd Font (rest) |

## Install

For Arch-based distros (Arch, CachyOS, EndeavourOS, …). You need an AUR helper (`yay` or `paru`).

```sh
git clone https://github.com/alpwrk/alpdots.git ~/alpdots
cd ~/alpdots
./install.sh
```

The script installs the packages, symlinks every folder in `config/` into `~/.config` and `home/.zshrc` to `~/.zshrc`. Any configs you already have get renamed to `<name>.bak-<timestamp>`, so nothing is lost.

On laptops (detected by a system battery in `/sys/class/power_supply`) it also writes `config/waybar/local.jsonc`, which puts the battery module at the far right of the bar. That file isn't tracked by git, so you can tweak it per machine.

It also makes zsh your login shell if it isn't already (`chsh` asks for your password).

If you're on a different distro or want to install the packages yourself:

```sh
./install.sh --no-deps
```

### Packages

All programs this rice uses, in one command (`swayfx`, `wlogout`, `swaylock-effects`, `wayfreeze` and `oh-my-zsh-git` are in the AUR on plain Arch). Clicking the screenshot notification opens GIMP, install `gimp` if you want that.:

```sh
yay -S --needed swayfx swaybg waybar rofi mako wlogout swaylock-effects ghostty grim slurp wayfreeze wl-clipboard libnotify brightnessctl playerctl wireplumber polkit-gnome pavucontrol blueman network-manager-applet ddcutil zsh oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting fastfetch yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide python-gobject gtk4 gtk4-layer-shell ttf-jetbrains-mono-nerd ttf-bigblueterminal-nerd
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
| `Super + Shift + O`          | opencode in a Ghostty window    |
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
| `AltGr + #`                  | Wallpaper switcher (bgswitch)   |
| `Super + Shift + C`          | Reload Sway and Waybar          |
| `Super + Shift + E`          | Exit Sway                       |
| `Print`                      | Freeze screen, screenshot area to `~/Pictures/Screenshots` + clipboard |
| `Ctrl + Alt + Ü / Ö / Ä`     | Play-pause / previous / next    |

Hover the right edge of the bar, just left of the volume, to slide out the tray, do-not-disturb toggle, network and bluetooth.

## Customize

- **Keyboard layout:** the config uses `de`. Change `xkb_layout` in `config/sway/config`.
- **Monitors:** the config sets `DP-1` to 1920x1080@180Hz with adaptive sync and has a commented second monitor (`HDMI-A-1`) with fixed workspaces 1-5 / 6-10. Change those lines to your outputs (list them with `swaymsg -t get_outputs`); any other output just uses its preferred mode.
- **Waybar:** `DP-1` and `HDMI-A-1` get their own bar with a DDC/CI brightness module (scroll on it, needs `ddcutil`), every other output gets a bar without it. Next to it is the now-playing (mpris) module.
- **Wallpaper:** press `AltGr + #` to open bgswitch, an Alt-Tab style picker. `Tab`/arrows/`h j k l` select, `Enter` sets, `Esc` cancels, and pressing `AltGr + #` again while it's open steps forward. It lists images from `config/sway/wallpaper/` and `~/Pictures/wallpapers/`, and the choice is kept as a symlink in `~/.cache/bgswitch/current`. For the lockscreen, change `image=` in `config/swaylock/config`.
- **Shell:** put machine-specific things (extra `PATH`s, `EDITOR`, …) into `~/.zshrc.local`, the tracked `.zshrc` sources it. Type `y` to open Yazi; when you quit, the shell `cd`s to where you were in Yazi.
- **Battery module:** to add or remove it by hand, create or delete `config/waybar/local.jsonc` (see `config/waybar/defaults.jsonc` for the default module list).
- **SwayFX effects:** blur settings only apply after a full Sway restart (log out and back in), not on reload.

## Uninstall

```sh
for d in ~/alpdots/config/*; do rm ~/.config/$(basename "$d"); done
rm ~/.zshrc
```

Then rename your `.bak-*` folders back if you want your old configs.
