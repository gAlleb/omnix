```
       ██████╗ ███╗   ███╗███╗   ██╗██╗██╗  ██╗
      ██╔═══██╗████╗ ████║████╗  ██║██║╚██╗██╔╝
█████╗██║   ██║██╔████╔██║██╔██╗ ██║██║ ╚███╔╝ █████╗
╚════╝██║   ██║██║╚██╔╝██║██║╚██╗██║██║ ██╔██╗ ╚════╝
      ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║██╔╝ ██╗
       ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
```

🥭🥭🥭

> [!TIP]
> A fully-configured, beautiful, modern NixOS desktop

> [!NOTE]
> with MangoWC, declaratively described in one flake.

🥭🥭🥭

## Quickstart

```bash
sudo nixos-rebuild switch --flake .#omnix       # real laptop
sudo nixos-rebuild switch --flake .#omnix-vm    # Proxmox VM
```

See [INSTALL.md](./INSTALL.md) for a step-by-step bring-up from a NixOS
installer ISO.

## Layout

```
flake.nix             # inputs (nixpkgs unstable, home-manager) + two hosts
hosts/
  omnix/              # real laptop: Intel iGPU, TLP, udev power-event
  omnix-vm/           # Proxmox VM: qemu-guest-agent, no TLP
modules/system/       # system modules (boot, audio, fonts, services, ...)
modules/home/         # home-manager modules (shell, git, tmux, gtk, ...)
pkgs/                 # custom packages not in nixpkgs:
  sfpro-display/      #   SF Pro Display (fetchurl GitHub release)
  photogimp-config/   #   PhotoGIMP config (pinned commit, deployed into
                      #   ~/.config/GIMP on first activation only)
  omnix-scripts/      #   wraps bin/omnix-* helper scripts as a package
overlays/             # plugs pkgs/ into the package set
config/               # "live" dotfiles — symlinked into ~/.config by HM
themes/               # pywal themes, referenced from ~/.config/omnix/
bin/                  # omnix-* helper scripts (theme/wallpaper/audio/waybar)
applications/         # .desktop / icons, symlinked into ~/.local/share/applications
default/xcompose      # base Compose table, read by home-manager
INSTALL.md            # step-by-step install from a NixOS ISO
```

## Applying changes

```bash
cd ~/.local/share/omnix
nix flake update                              # bump inputs
sudo nixos-rebuild switch --flake .#omnix
sudo nixos-rebuild switch --rollback          # back to the previous generation
```

## What's declarative vs symlinked

| Source of truth | What lives there |
|---|---|
| Nix (read-only in `/nix/store`) | git config, bash env, tmux, GTK/Qt theming, fonts, XCompose, MIME defaults |
| Symlink → `config/<app>/` (mutable, in the repo) | waybar, mango, swaync, mako, rofi, walker, wal, wallpaper, alacritty, kitty, ghostty, nvim, mpd, mpv, fastfetch, yazi, crystal-dock, swayidle, swaylock, swayosd, wlogout, nwg-dock-hyprland, rmpc, senpai, waypaper, hypr |

The symlinked configs are the ones the `omnix-theme-*` / pywal scripts
mutate at runtime — they have to stay writable.

## Themes (Alt+W to cycle)

`bin/omnix-init-wallpaper` picks a random theme from `themes/` on first
session start. After that, `Alt+W` (or the rofi launcher) re-rolls the
wallpaper and pywal regenerates the colour palette in `~/.cache/wal/`,
which the `wal/`, `waybar/`, `mako/`, `swaync/`, `rofi/`, `walker/` and
`mango/` configs include.

The SDDM login background follows the same source: a systemd one-shot
unit (`omnix-sddm-background.service`) copies `~/.config/bg.jpg` into
`/var/lib/sddm/background.jpg` before every display-manager start, and
a patched `sddm-astronaut` derivation points the theme at that absolute
path. New wallpaper -> visible on the SDDM screen at next login.
