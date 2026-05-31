# Installing NixOS from this flake

> Goal: a system you bring up with `sudo nixos-rebuild switch --flake .#omnix`
> (or `.#omnix-vm` for a Proxmox dry-run).

Two hosts are defined:

| Host | When to use |
|---|---|
| `.#omnix-vm` | Proxmox / QEMU VM. No TLP, no intel-media-driver, ships `qemu-guest-agent`. |
| `.#omnix`    | Real laptop. TLP, intel-media-driver, udev power-event rule. |

---

## The plan

Install vanilla NixOS from the **minimal ISO** the usual way (partition,
mount, generate config, edit, `nixos-install`). The base install only
needs to give us a bootable system with the `stefan` user and network.
After the first reboot we clone the flake into `~/.local/share/omnix/`
and `nixos-rebuild switch --flake .#omnix-vm` replaces the vanilla
config with this one (SDDM + Mango + dotfiles + themes + apps).

---

## 1. Get the ISO and boot it

Download **NixOS minimal** from <https://nixos.org/download>. Write to USB:

```sh
sudo dd if=nixos-minimal-….iso of=/dev/sdX bs=4M status=progress oflag=sync
```

For Proxmox just attach the ISO. Boot it — you land as `nixos@nixos`
with no password (sudo without prompt).

Bring up network:

```sh
# wired usually auto-comes-up; for wifi:
sudo systemctl start wpa_supplicant
nmcli device wifi connect <SSID> password <PW>
```

---

## 2. Partition + format + mount

Find your disk with `lsblk` (in Proxmox typically `/dev/sda` or `/dev/vda`).

### UEFI (recommended)

```sh
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart ESP fat32 1MiB 1GiB
sudo parted /dev/sda -- set 1 esp on
sudo parted /dev/sda -- mkpart primary ext4 1GiB 100%

sudo mkfs.fat -F 32 -n boot /dev/sda1
sudo mkfs.ext4 -L nixos /dev/sda2

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

### Legacy BIOS

```sh
sudo parted /dev/sda -- mklabel msdos
sudo parted /dev/sda -- mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 -L nixos /dev/sda1
sudo mount /dev/disk/by-label/nixos /mnt
```

For BIOS also set `boot.loader.grub.efiSupport = false;` and
`boot.loader.grub.device = "/dev/sda";` in the flake later
(`modules/system/boot.nix`).

---

## 3. Generate base config

```sh
sudo nixos-generate-config --root /mnt
```

Produces:
- `/mnt/etc/nixos/hardware-configuration.nix` — UUIDs, kernel modules
  for this exact machine. We don't touch it.
- `/mnt/etc/nixos/configuration.nix` — base config we edit next.

---

## 4. Edit `configuration.nix` for the bare-bones install

Open it:

```sh
sudo nano /mnt/etc/nixos/configuration.nix
```

Replace the content with the following. The only goal here is to
boot, log in as `stefan` with network and `git`. Mango/SDDM/dotfiles
arrive in step 6.

```nix
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader — match what you set up in step 2.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";              # set to "/dev/sda" for BIOS
    efiSupport = true;             # set to false for BIOS
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;  # drop for BIOS

  networking.hostName = "omnix-vm";   # or "omnix"
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.stefan = {
    isNormalUser = true;
    description = "Stefan";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";    # set a real password after first login
  };

  # SSH from your host into the VM for the rest of the install.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    openFirewall = true;
  };

  # Flakes are required for `nixos-rebuild --flake`.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "25.05";   # keep whatever the generator put here
}
```

Notes:
- `initialPassword = "changeme"` is plaintext — fine for a bring-up,
  change with `passwd` after first login. If that's still too gross
  for you, drop the line and run `nixos-enter --root /mnt -c 'passwd stefan'`
  after step 5.
- The hostname here is overridden when the flake takes over, so it's
  fine to set it to anything.

---

## 5. Install

```sh
sudo nixos-install --no-root-passwd
sudo reboot
```

The `--no-root-passwd` flag is fine because `stefan` is in `wheel`
and that's how we'll do anything `root`-level.

---

## 6. First boot → SSH in → clone the flake → take over

Log in at the TTY as `stefan` with the password from step 4
(`changeme`). Change it and find the IP:

```sh
passwd
ip -4 addr show | awk '/inet /{print $2}'
```

Now you can SSH in from your host machine and continue from there
(easier copy-paste, real terminal):

```sh
ssh stefan@<vm-ip>
```

Pull the flake into its real home (the path matters — see "Why this
exact path" below):

```sh
mkdir -p ~/.local/share
git clone -b omnix-mango https://github.com/galleb/omvoid.git \
  ~/.local/share/omnix

# CRITICAL: replace the placeholder hardware-configuration.nix in the
# repo with the real one that nixos-generate-config wrote for your
# machine. The repo file is a stub for `nix flake check` only — if
# left in place, boot will hang waiting for a non-existent partition
# (the stub assumes a separate /boot which BIOS installs don't have).
sudo cp /etc/nixos/hardware-configuration.nix \
  ~/.local/share/omnix/hosts/omnix-vm/hardware-configuration.nix
sudo chown $USER:users \
  ~/.local/share/omnix/hosts/omnix-vm/hardware-configuration.nix
# (use hosts/omnix/ instead of hosts/omnix-vm/ for the real laptop)

cd ~/.local/share/omnix
sudo nixos-rebuild boot --flake .#omnix-vm     # or .#omnix
sudo reboot
```

`nixos-rebuild boot` (rather than `switch`) builds the new generation
and marks it default for the next boot, without restarting anything
in the current session. This avoids a known dbus-broker race that
hangs `switch` indefinitely when user units change inside the
active login. After `reboot` you'll come up directly in the new
generation with SDDM + Mango + dotfiles + themes + fonts + omnix-*
helpers + all the symlinks under `~/.config/`.

> **Why this exact path?** Home-manager hardcodes
> `~/.local/share/omnix/` as the target of its `mkOutOfStoreSymlink`
> calls (see `modules/home/dotfiles.nix`). The symlinks under
> `~/.config/` will point at `~/.local/share/omnix/config/*`, so the
> repo has to live there for them to resolve.

> **Why the explicit hardware-config copy?** Earlier versions of the
> flake tried to auto-pick `/etc/nixos/hardware-configuration.nix`
> via `builtins.pathExists`. That doesn't work in flake (sandboxed)
> evaluation — paths outside the flake aren't visible, so the call
> always returned `false` and the placeholder won. Explicit copy is
> the only path that's actually reliable.

If the build hits **`hash mismatch in fixed-output derivation`** in
`pkgs/sfpro-display/` or `pkgs/photogimp-config/`, copy the
`got: sha256-…` value from the error into the corresponding
`default.nix` and re-run. See "Known gotchas" below.

---

## 7. Reboot

```sh
sudo reboot
```

You land in SDDM with the astronaut theme. Pick the **MangoWC**
session, log in.

---

## 8. One-time manual bits

| Task | How |
|---|---|
| Passwords for CIFS mounts | Create `/etc/autofs/credentials` (see `modules/system/filesystems.nix`) |
| `rclone` config | `rclone config` — writes `~/.config/rclone/rclone.conf` |
| autofs mappings | Edit `/etc/autofs/auto.mymounts` (hints are in the comments) |
| First wallpaper / theme | `omnix-init-wallpaper` — picks a random theme from `themes/` |
| Discord / Brave sign-in | Sign in manually after first launch |

---

## 9. Day-to-day updates

```sh
cd ~/.local/share/omnix
nix flake update                              # bump inputs
sudo nixos-rebuild switch --flake .#omnix
sudo nixos-rebuild switch --rollback          # back to the previous generation
```

Or pick an older generation from the GRUB menu at boot.

---

## 10. Known gotchas

- **`sha256 = "00000…"` placeholders in `pkgs/`.** First build will
  fail with `hash mismatch in fixed-output derivation`. Copy the
  `got: sha256-…` value from the error into
  `pkgs/sfpro-display/default.nix` and `pkgs/photogimp-config/default.nix`,
  rerun. From the second build on these are cached.
- **Mango doesn't show up in the SDDM session list.** Confirm the
  rebuild finished cleanly, then restart SDDM:
  `systemctl restart display-manager`.
- **Intel iGPU video acceleration not kicking in.** Make sure you used
  the `.#omnix` host (not `.#omnix-vm`) — `omnix.profile.intel = true`
  is what pulls in `intel-media-driver`.
- **Forgot to enable flakes in step 4 `configuration.nix`.** You'll
  get `error: experimental Nix feature 'nix-command' is disabled` on
  the first `nixos-rebuild --flake`. Add the
  `nix.settings.experimental-features` line, then
  `sudo nixos-rebuild switch` (without `--flake`) — that picks up the
  edit, and after that `--flake` works.
