# alpdots

A minimal monochrome Sway rice: borderless SwayFX windows with blur, a half-transparent Waybar you can tint with the wallpaper's colors, a mono Rofi launcher, Mako notifications, Wlogout and Swaylock.

| Component    | Config                  |
|--------------|-------------------------|
| WM           | SwayFX                  |
| Bar          | Waybar                  |
| Launcher     | Rofi                    |
| Notifications| Mako                    |
| Power menu   | Wlogout                 |
| Lockscreen   | Swaylock-effects        |
| Terminal     | Ghostty                 |
| Shell        | zsh + oh-my-posh        |
| File manager | Yazi                    |
| Fetch        | Fastfetch               |
| Wallpaper    | bgswitch (GTK4 overlay, also sets the bar color) |
| Font         | BigBlueTerm Nerd Font (bar, terminal), JetBrainsMono Nerd Font (rest) |

## Install

For Arch-based distros (Arch, CachyOS, EndeavourOS, …) with an AUR helper (`yay` or `paru`), and for FreeBSD (needs `sudo` or `doas`, packages come from `pkg`). The script is plain `sh`, so bash isn't required.

```sh
git clone https://github.com/alpwrk/alpdots.git ~/alpdots
cd ~/alpdots
./install.sh
```

The script installs the packages, symlinks every folder in `config/` into `~/.config`, `home/.zshrc` to `~/.zshrc` and the GTK `settings.ini` files from `gtk/`. It also sets dark mode via gsettings (`adw-gtk3-dark`, Breeze Dark icons, Capitaine cursors, Noto Sans), which Qt apps pick up through the GTK portal. Any configs you already have get renamed to `<name>.bak-<timestamp>`, so nothing is lost.

On laptops (detected by a system battery in `/sys/class/power_supply`, or `hw.acpi.battery.units` on FreeBSD) it also writes `config/waybar/local.jsonc`, which puts the battery module at the far right of the bar. That file isn't tracked by git, so you can tweak it per machine.

It also writes `config/waybar/accent.css` with the default bar colors (half-transparent black). bgswitch overwrites it when you pick a bar color, so it's not tracked by git either.

It also makes zsh your login shell if it isn't already (`chsh` asks for your password).

### FreeBSD

`./install.sh` installs the FreeBSD versions of the packages. Names `pkg` doesn't know are skipped with a warning (install those yourself or leave them out). At the end it prints the system setup sway needs, which it doesn't do for you:

```sh
sudo sysrc seatd_enable=YES dbus_enable=YES
sudo service seatd start && sudo service dbus start
sudo pw groupmod video -m "$USER"
```

If `pkg` has no oh-my-posh, the shell uses a built-in zsh prompt that looks the same (`path (branch*) $`). To get oh-my-posh anyway, install it from [ohmyposh.dev](https://ohmyposh.dev/docs/installation/linux), it has FreeBSD builds.

Some Linux-only bits don't work there: DDC/CI and backlight brightness (`ddcutil`, `brightnessctl`), the screen freeze while taking a screenshot (`wayfreeze`, screenshots still work) and Blueman.

### Other systems

If you're on a different distro or want to install the packages yourself:

```sh
./install.sh --no-deps
```

### Packages

All programs this rice uses, in one command (`swayfx`, `wlogout`, `swaylock-effects`, `wayfreeze` and `oh-my-posh-bin` are in the AUR on plain Arch). Clicking the screenshot notification opens GIMP, install `gimp` if you want that:

```sh
yay -S --needed swayfx swaybg waybar rofi dmenu mako wlogout swaylock-effects ghostty grim slurp wayfreeze wl-clipboard libnotify brightnessctl playerctl wireplumber polkit-gnome pavucontrol blueman network-manager-applet ddcutil zsh oh-my-posh-bin zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fastfetch yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide python-gobject gtk4 gtk4-layer-shell adw-gtk-theme breeze-icons capitaine-cursors noto-fonts xdg-desktop-portal-gtk xdg-desktop-portal-wlr ttf-jetbrains-mono-nerd ttf-bigblueterminal-nerd
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
| `AltGr + -`                  | Dismiss the newest notification |
| `AltGr + Shift + -`          | Restore the last dismissed notification |
| `Super + Shift + C`          | Reload Sway and Waybar          |
| `Super + Shift + E`          | Exit Sway                       |
| `Print`                      | Freeze screen, screenshot area to `~/Pictures/Screenshots` + clipboard |
| `Ctrl + Alt + Ü / Ö / Ä`     | Play-pause / previous / next    |

Hover the right edge of the bar, just left of the volume, to slide out the tray, do-not-disturb toggle, network and bluetooth.

## Customize

- **Keyboard layout:** the config uses `de`. Change `xkb_layout` in `config/sway/config`.
- **Monitors:** the config sets `DP-1` to 1920x1080@180Hz with adaptive sync and has a commented second monitor (`HDMI-A-1`) with fixed workspaces 1-5 / 6-10. Change those lines to your outputs (list them with `swaymsg -t get_outputs`); any other output just uses its preferred mode.
- **Waybar:** `DP-1` and `HDMI-A-1` get their own bar with a DDC/CI brightness module (scroll on it, needs `ddcutil`), every other output (e.g. a laptop panel) gets a bar with the regular backlight module instead (scroll to change it). Next to it is the now-playing (mpris) module.
- **Wallpaper:** press `AltGr + #` to open bgswitch, an Alt-Tab style picker with a big preview. `Tab`/`←`/`→`/`h`/`l` select and the wallpaper changes live while you browse, `Enter` keeps it, `Esc` goes back to the old one, and pressing `AltGr + #` again while it's open steps forward. `↓`/`j` jumps to the color row below: transparent, three accent colors taken from the selected wallpaper and ten standard colors. `Enter` there sets the Waybar background (text switches between black and white for contrast), `↑`/`k` goes back up. It lists images from `config/sway/wallpaper/` and `~/Pictures/wallpapers/` (or `$BGSWITCH_DIR`), and the choice is kept as a symlink in `~/.cache/bgswitch/current`. For the lockscreen, change `image=` in `config/swaylock/config`.
- **Shell:** put machine-specific things (extra `PATH`s, `EDITOR`, …) into `~/.zshrc.local`, the tracked `.zshrc` sources it. Type `y` to open Yazi; when you quit, the shell `cd`s to where you were in Yazi. `Up`/`Down` search the history for what you've typed, `Ctrl + R`/`Ctrl + T`/`Alt + C` are fzf (history, files, cd) and `z <part of a dir>` jumps with zoxide. The prompt theme is `config/oh-my-posh/mytheme.omp.toml`.
- **Battery module:** to add or remove it by hand, create or delete `config/waybar/local.jsonc` (see `group/laptop` in `config/waybar/config.common.jsonc`).
- **Shell parts:** the bar, launcher, notification, power menu and wallpaper binds live in `config/sway/shell.conf`, so swapping any of them out only touches that file.
- **SwayFX effects:** blur settings only apply after a full Sway restart (log out and back in), not on reload.

## Uninstall

```sh
for d in ~/alpdots/config/*; do rm ~/.config/$(basename "$d"); done
rm ~/.zshrc ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
```

Then rename your `.bak-*` folders back if you want your old configs.
