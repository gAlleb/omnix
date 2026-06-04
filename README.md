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

<img width="800" alt="изображение" src="https://github.com/user-attachments/assets/a73049f9-0952-4c20-be6f-e733f8e5cce2" />

## Quickstart

Eight hardware-aware default hosts are ready out of the box:

```bash
sudo nixos-rebuild switch --flake .#omnix-vm                    # Proxmox / QEMU VM
sudo nixos-rebuild switch --flake .#omnix-intel-laptop          # Intel iGPU laptop
sudo nixos-rebuild switch --flake .#omnix-intel-desktop         # Intel iGPU desktop
sudo nixos-rebuild switch --flake .#omnix-amd-laptop            # AMD GPU laptop
sudo nixos-rebuild switch --flake .#omnix-amd-desktop           # AMD GPU desktop
sudo nixos-rebuild switch --flake .#omnix-nvidia-intel-laptop   # Intel CPU + NVIDIA dGPU laptop (PRIME)
sudo nixos-rebuild switch --flake .#omnix-nvidia-amd-laptop     # AMD CPU + NVIDIA dGPU laptop (PRIME)
sudo nixos-rebuild switch --flake .#omnix-nvidia-desktop        # Discrete NVIDIA desktop (any CPU)
```

Plus **custom hosts** — `hosts/<your-name>/` is auto-picked up by
`flake.nix` via `builtins.readDir`, no edits needed. The installer
creates it for you.

## Install

Two scripts in `install/` walk you from a freshly-booted NixOS ISO to
a running mango desktop:

```bash
# 1) On the install ISO (after partitioning + mount):
curl -L https://raw.githubusercontent.com/galleb/omnix/refs/heads/main/install/phase1-iso.sh | sudo bash

# 2) After first boot, logged in as your user:
curl -L https://raw.githubusercontent.com/galleb/omnix/refs/heads/main/install/phase2-system.sh | bash
```

Phase 1 auto-detects GPU / form-factor / boot mode, asks a handful of
questions, writes a minimal `configuration.nix`, runs `nixos-install`
and reboots. Phase 2 clones the flake into `~/.local/share/omnix`,
writes `hosts/<host>/variables.nix` with your answers, copies the
real `hardware-configuration.nix` into place, and runs
`nixos-rebuild boot --flake .#<host>`. See [INSTALL.md](./INSTALL.md)
for full step-by-step.

## Layout

```
flake.nix             # inputs (nixpkgs unstable, home-manager,
                      # tmux-nerd-font-window-name). nixosConfigurations
                      # auto-discovered from hosts/<x>/variables.nix.
hosts/
  omnix-vm/                  # Proxmox / QEMU VM
  omnix-intel-laptop/        # Intel iGPU laptop (TLP, brightness)
  omnix-intel-desktop/
  omnix-amd-laptop/
  omnix-amd-desktop/
  omnix-nvidia-intel-laptop/ # Intel + NVIDIA hybrid laptop (PRIME)
  omnix-nvidia-amd-laptop/   # AMD + NVIDIA hybrid laptop (PRIME)
  omnix-nvidia-desktop/      # Discrete NVIDIA desktop
  <yours>/                   # any directory you drop here becomes .#<yours>
profiles/             # hardware profiles. Each one imports the host +
                      # modules/system + modules/drivers and flips on
                      # the right drivers.<x>.enable booleans.
modules/drivers/      # one option-based module per hw category:
  intel.nix           #   intel-media-driver, LIBVA, thermald
  amd.nix             #   amdvlk
  nvidia.nix          #   NVIDIA drivers (modesetting, open kernel)
  nvidia-prime.nix    #   PRIME offload for hybrid iGPU+dGPU laptops
  laptop.nix          #   TLP, upower, brightnessctl, udev AC events
  vm.nix              #   qemu-guest-agent, spice
modules/system/       # boot, networking, locale, users, audio, bluetooth,
                      # desktop, fonts, docker, services, filesystems,
                      # packages, nix, ssh
modules/home/         # home-manager modules (shell, git, tmux, gtk, ...)
pkgs/                 # custom packages not in nixpkgs:
  sfpro-display/      #   SF Pro Display (fetchurl GitHub release)
  photogimp-config/   #   PhotoGIMP config (deployed into ~/.config/GIMP
                      #   on first activation only)
  omnix-scripts/      #   wraps bin/omnix-* helper scripts as a package
  wal-telegram/       #   pywal palette → Telegram theme converter
overlays/             # plugs pkgs/ into the package set
config/               # "live" dotfiles — symlinked into ~/.config by HM
themes/               # pywal themes
bin/                  # omnix-* helper scripts (theme/wallpaper/font/...)
applications/         # .desktop / icons, deployed into ~/.local/share/*
install/              # phase1-iso.sh + phase2-system.sh
INSTALL.md            # step-by-step install
```

Per-host configuration (username, timezone, LAN subnet, bootMode,
swapSize, git persona, extras toggle, drivers profile) lives in
`hosts/<x>/variables.nix`. Each `default.nix` reads from there; no
hardcoded values.

## Applying changes

```bash
cd ~/.local/share/omnix
nix flake update                                # bump inputs
sudo nixos-rebuild switch --flake .#<host>
sudo nixos-rebuild switch --rollback            # previous generation
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
