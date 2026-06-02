# Installing NixOS from this flake

> Goal: a system you bring up with `sudo nixos-rebuild switch --flake .#omnix`
> (or `.#omnix-vm` for a Proxmox dry-run).

Two hosts are defined:

| Host | When to use |
|---|---|
| `.#omnix-vm` | Proxmox / QEMU VM. No TLP, no intel-media-driver, ships `qemu-guest-agent`. |
| `.#omnix`    | Real laptop. TLP, intel-media-driver, udev power-event rule. |

How a host gets its drivers: `flake.nix` `mkHost` maps a hostName to a
profile name (`omnix → intel-laptop`, `omnix-vm → vm`). Each profile
under `profiles/<x>/default.nix` imports the host config, `modules/system`,
and `modules/drivers`, then flips on the right
`drivers.{intel,amd,laptop,vm}.enable` flags. To add an AMD host
later: create `hosts/omnix-amd/`, create `profiles/amd-laptop/` (with
`drivers.amd.enable = true; drivers.laptop.enable = true;`), and add
one line to `nixosConfigurations` in `flake.nix`.

---

## The plan

Install vanilla NixOS from the **minimal ISO** the usual way (partition,
mount, generate config, install). Two helper scripts under `install/`
take care of the boring parts:

| Step | What | When | Run as |
|---|---|---|---|
| `install/phase1-iso.sh` | Asks host / boot / disk / username / timezone / LAN subnet / extras / git persona / initial password. Generates `/mnt/etc/nixos/configuration.nix` and saves the answers to `/mnt/etc/omnix-install.env`. | On the install ISO, after partitioning + mount. | `root` (`sudo`) |
| `install/phase2-system.sh` | Reads `/etc/omnix-install.env`, clones this flake into `~/.local/share/omnix`, copies `hardware-configuration.nix` into the repo, writes `hosts/<host>/variables.nix` with the answers, runs `nixos-rebuild boot --flake`. | After first boot, logged in as your user. | your user |

Neither script touches the disk. Partitioning, `nixos-install`, and the
final reboot are still your call.

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

---

## 3. Run phase 1

This single command does what steps 3 + 4 of the old README did
(`nixos-generate-config` and writing a minimal `configuration.nix`):

```sh
curl -L https://raw.githubusercontent.com/galleb/omvoid/omnix-mango/install/phase1-iso.sh | sudo bash
```

It asks:

| Question | Default | Notes |
|---|---|---|
| Host profile | `omnix-vm` | `omnix` for the real laptop |
| Boot mode | `uefi` | `bios` for legacy installs |
| Disk for GRUB | `/dev/sda` | BIOS only |
| Username | `stefan` | Your account name |
| Timezone | `Europe/Moscow` | Any `tzdata` zone |
| LAN subnet | `192.168.1.0/24` | Subnet allowed through the firewall |
| Heavy extras | `N` | Brave, Chromium, VLC, OBS, Telegram, Audacity, etc. Skip on a tiny VM. |
| Initial password | — | Hashed with `mkpasswd -m sha-512` |

When it finishes, you get a minimal `configuration.nix` that boots
into a usable system with `git`, SSH and your user — nothing else.
The answers also live in `/mnt/etc/omnix-install.env` so phase 2 can
read them.

The script also offers to run `nixos-install --no-root-passwd` and to
reboot when it finishes. Answer `y` to both unless something looks off
in the generated config — there's no separate manual `nixos-install`
step. (`--no-root-passwd` is fine because your user is in `wheel`.)

---

## 4. First boot → run phase 2

Log in at the TTY as the user you picked. You can keep going at the
TTY, or SSH in from another machine (easier copy-paste):

```sh
ip -4 addr show | awk '/inet /{print $2}'
# from your host:
ssh <username>@<vm-ip>
```

Then:

```sh
curl -L https://raw.githubusercontent.com/galleb/omvoid/omnix-mango/install/phase2-system.sh | bash
```

Phase 2:
1. Reads `/etc/omnix-install.env` (written by phase 1) for defaults and
   asks you to confirm host / timezone / LAN subnet — press Enter to
   keep the values you picked during phase 1, or type a new one.
2. Persists your answers back to `/etc/omnix-install.env`.
3. If `~/.local/share/omnix` doesn't exist yet — clones the flake there
   and patches `flake.nix` (`username`), `modules/system/locale.nix`
   (`time.timeZone`) and `modules/system/networking.nix` (`ip saddr`
   in the firewall) with the answers from step 1. If the repo already
   exists, clone + patches are skipped (the hardcoded strings the
   patches look for would already be gone).
4. Copies the real `/etc/nixos/hardware-configuration.nix` into
   `hosts/<host>/` in the repo, replacing the placeholder.
5. Runs `sudo nixos-rebuild boot --flake .#<host>`.
6. Asks whether to reboot now.

> **Re-running phase 2 with different parameters.** The sed patches in
> step 3 only fire on a freshly-cloned repo. If you want to change
> username / timezone / LAN subnet on an already-installed machine,
> `rm -rf ~/.local/share/omnix` first, then re-run phase 2 — it'll
> clone fresh and re-apply the patches with whatever you enter at the
> prompts.

> **Why this exact path?** Home-manager hardcodes
> `~/.local/share/omnix/` as the target of its `mkOutOfStoreSymlink`
> calls (see `modules/home/dotfiles.nix`). The symlinks under
> `~/.config/` will point at `~/.local/share/omnix/config/*`, so the
> repo has to live there for them to resolve.

> **Why `nixos-rebuild boot` instead of `switch`?** `boot` stages the
> new generation for the next boot without restarting anything in the
> current session. `switch` here can hang on a dbus-broker race when
> user units change inside the active login. After `reboot` you come
> up directly in the new generation.

> **Why the explicit hardware-config copy?** Earlier versions of the
> flake tried to auto-pick `/etc/nixos/hardware-configuration.nix` via
> `builtins.pathExists`. That doesn't work in pure flake evaluation —
> paths outside the flake aren't visible, so the call always returned
> `false` and the placeholder won. Explicit copy is the only reliable
> path.

If the build hits **`hash mismatch in fixed-output derivation`** in
`pkgs/sfpro-display/` or `pkgs/photogimp-config/`, copy the
`got: sha256-…` value from the error into the corresponding
`default.nix` and re-run. See "Known gotchas" below.

---

## 5. Land in MangoWC

After the reboot triggered by phase 2 you get SDDM with the astronaut
theme. Pick the **MangoWC** session, log in with the password you set
during phase 1.

---

## 6. One-time manual bits

| Task | How |
|---|---|
| Passwords for CIFS mounts | Create `/etc/autofs/credentials` (see `modules/system/filesystems.nix`) |
| `rclone` config | `rclone config` — writes `~/.config/rclone/rclone.conf` |
| autofs mappings | Edit `/etc/autofs/auto.mymounts` (hints are in the comments) |
| First wallpaper / theme | `omnix-init-wallpaper` — picks a random theme from `themes/` |
| Discord / Brave sign-in | Sign in manually after first launch |

---

## 7. Day-to-day updates

```sh
cd ~/.local/share/omnix
nix flake update                              # bump inputs
sudo nixos-rebuild switch --flake .#omnix
sudo nixos-rebuild switch --rollback          # back to the previous generation
```

Or pick an older generation from the GRUB menu at boot.

---

## 8. Known gotchas

- **`sha256 = "00000…"` placeholders in `pkgs/`.** First build will
  fail with `hash mismatch in fixed-output derivation`. Copy the
  `got: sha256-…` value from the error into
  `pkgs/sfpro-display/default.nix` and `pkgs/photogimp-config/default.nix`,
  rerun. From the second build on these are cached.
- **Mango doesn't show up in the SDDM session list.** Confirm the
  rebuild finished cleanly, then restart SDDM:
  `systemctl restart display-manager`.
- **Intel iGPU video acceleration not kicking in.** Make sure you used
  the `.#omnix` host (not `.#omnix-vm`) — `omnix` maps to the
  `intel-laptop` profile in `flake.nix`, which flips on
  `drivers.intel.enable = true` (defined in `modules/drivers/intel.nix`)
  and that's what pulls in `intel-media-driver` + `LIBVA_DRIVER_NAME=iHD`.
- **Phase 2 says `Cannot read /etc/omnix-install.env`.** Either phase 1
  didn't run, or you did `nixos-install` from a different `/mnt`. Re-run
  phase 1 on the actual target root.
- **Phase 2 says `expects to run as '<x>', not '<y>'`.** You logged in
  as a different user than the one phase 1 created. Log in as the
  username you set during phase 1.
