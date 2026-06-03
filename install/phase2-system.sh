#!/usr/bin/env bash
#
# omnix install — phase 2 (runs after first boot, as your user).
#
# Reads /etc/omnix-install.env (written by phase 1) for defaults and asks
# you to confirm host / timezone / LAN subnet / extras / git persona.
# Then:
#
#   - If ~/.local/share/omnix doesn't exist: clones the flake there and
#     writes hosts/$HOST/variables.nix with the answers (this is the
#     single file the repo reads all bootstrap values from).
#   - If it does exist: skips clone + variables.nix write (the file
#     has likely already been customised) and runs rebuild against the
#     current repo state.
#
# Either way it copies the real /etc/nixos/hardware-configuration.nix
# into the repo, persists your answers back to /etc/omnix-install.env,
# runs `nixos-rebuild boot --flake .#$HOST`, and offers to reboot.
#
# To re-apply with new values: `rm -rf ~/.local/share/omnix` and run
# this script again.
#
set -euo pipefail

ENV_FILE=/etc/omnix-install.env

# Defaults, possibly overridden by env file
DEFAULT_HOST=omnix-vm
DEFAULT_PROFILE=vm
DEFAULT_SWAP_SIZE=8192
DEFAULT_TIMEZONE="Europe/Moscow"
DEFAULT_LAN_SUBNET=192.168.1.0/24
DEFAULT_EXTRAS=false
DEFAULT_FULL_NAME=""
DEFAULT_EMAIL=""
EXPECTED_USER=$USER

if [ -r "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  DEFAULT_HOST=${OMNIX_HOST:-$DEFAULT_HOST}
  DEFAULT_PROFILE=${OMNIX_PROFILE:-$DEFAULT_PROFILE}
  DEFAULT_SWAP_SIZE=${OMNIX_SWAP_SIZE:-$DEFAULT_SWAP_SIZE}
  DEFAULT_TIMEZONE=${OMNIX_TIMEZONE:-$DEFAULT_TIMEZONE}
  DEFAULT_LAN_SUBNET=${OMNIX_LAN_SUBNET:-$DEFAULT_LAN_SUBNET}
  DEFAULT_EXTRAS=${OMNIX_EXTRAS:-$DEFAULT_EXTRAS}
  DEFAULT_FULL_NAME=${OMNIX_FULL_NAME:-$DEFAULT_FULL_NAME}
  DEFAULT_EMAIL=${OMNIX_EMAIL:-$DEFAULT_EMAIL}
  EXPECTED_USER=${OMNIX_USERNAME:-$USER}
  # OMNIX_BOOT_MODE / OMNIX_BIOS_DEVICE are used later, not asked here.
fi

# Fallbacks if env file didn't carry them (e.g. phase1 was run before
# this commit landed)
: "${DEFAULT_FULL_NAME:=$USER}"
: "${DEFAULT_EMAIL:=$USER@$DEFAULT_HOST}"

if [ "$USER" != "$EXPECTED_USER" ]; then
  echo "Warning: phase 1 created user '$EXPECTED_USER', but you're logged in as '$USER'." >&2
  read -rp "Continue with '$USER' anyway? (y/N): " ANS </dev/tty
  [[ "$ANS" =~ ^[Yy]$ ]] || exit 1
fi

# All `read` calls go to /dev/tty so the script works when piped via
# `curl … | bash` — without this, read steals stdin from the pipe and
# eats the next lines of the script itself.
ask() {
  local prompt="$1" default="$2" var
  read -rp "$prompt [$default]: " var </dev/tty
  echo "${var:-$default}"
}

HOST=$(ask "Host name" "$DEFAULT_HOST")

if [[ ! "$HOST" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid host name '$HOST' — use lowercase letters, digits and hyphens only." >&2
  exit 1
fi

case "$HOST" in
  omnix-vm|omnix-intel-laptop|omnix-intel-desktop|omnix-amd-laptop|omnix-amd-desktop)
    # Default host — profile follows the suffix.
    PROFILE="${HOST#omnix-}"
    ;;
  *)
    # Custom host — confirm profile (defaults to whatever phase1 picked).
    echo ""
    echo "Custom host '$HOST'. Which hardware profile should it use?"
    echo "  vm | intel-laptop | intel-desktop | amd-laptop | amd-desktop"
    PROFILE=$(ask "Profile" "$DEFAULT_PROFILE")
    case "$PROFILE" in
      vm|intel-laptop|intel-desktop|amd-laptop|amd-desktop) ;;
      *) echo "Unknown profile: $PROFILE" >&2; exit 1 ;;
    esac
    ;;
esac

# Boot mode and biosDevice are NOT asked here.
#  - In the typical phase1 → install → phase2 flow they come from
#    /etc/omnix-install.env (phase1 set them).
#  - If env is missing (user cloned the repo onto an already-running
#    system that wasn't installed via phase1) we detect bootMode from
#    /sys/firmware/efi/efivars — its mere existence is authoritative
#    proof that the kernel booted UEFI. biosDevice falls back to
#    /dev/sda; the user can edit hosts/<host>/variables.nix later.
#
# Why not ask? Because by phase2 time the bootloader is already on
# the disk. Letting the user "change" bootMode in a prompt would just
# write a wrong value into variables.nix and break the next rebuild.
if [ -n "${OMNIX_BOOT_MODE:-}" ]; then
  BOOT_MODE=$OMNIX_BOOT_MODE
else
  if [ -d /sys/firmware/efi/efivars ]; then
    BOOT_MODE=uefi
  else
    BOOT_MODE=bios
  fi
  echo "==> Detected boot mode: $BOOT_MODE (no /etc/omnix-install.env)"
fi

BIOS_DEVICE=${OMNIX_BIOS_DEVICE:-}
[ -n "$BIOS_DEVICE" ] || BIOS_DEVICE=/dev/sda
if [ "$BOOT_MODE" = "bios" ] && [ -z "${OMNIX_BIOS_DEVICE:-}" ]; then
  echo "==> Assuming biosDevice = $BIOS_DEVICE — edit hosts/$HOST/variables.nix if your GRUB disk is different."
fi

SWAP_SIZE=$(ask "Swap size in MiB" "$DEFAULT_SWAP_SIZE")
if [[ ! "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
  echo "Invalid swap size: $SWAP_SIZE" >&2; exit 1
fi

TIMEZONE=$(ask "Timezone" "$DEFAULT_TIMEZONE")
LAN_SUBNET=$(ask "LAN subnet allowed through firewall" "$DEFAULT_LAN_SUBNET")

if [ "$DEFAULT_EXTRAS" = "true" ]; then
  read -rp "Install heavy extras (brave, chromium, vlc, obs, …)? (Y/n): " EXTRAS_ANS </dev/tty
  if [[ "$EXTRAS_ANS" =~ ^[Nn]$ ]]; then EXTRAS=false; else EXTRAS=true; fi
else
  read -rp "Install heavy extras (brave, chromium, vlc, obs, …)? (y/N): " EXTRAS_ANS </dev/tty
  if [[ "$EXTRAS_ANS" =~ ^[Yy]$ ]]; then EXTRAS=true; else EXTRAS=false; fi
fi

FULL_NAME=$(ask "Full name for git commits" "$DEFAULT_FULL_NAME")
EMAIL=$(ask "Email for git commits" "$DEFAULT_EMAIL")

USERNAME=$USER

echo "==> Persisting answers to $ENV_FILE"
sudo tee "$ENV_FILE" >/dev/null <<EOF
OMNIX_HOST=$HOST
OMNIX_PROFILE=$PROFILE
OMNIX_BOOT_MODE=$BOOT_MODE
OMNIX_BIOS_DEVICE=$BIOS_DEVICE
OMNIX_SWAP_SIZE=$SWAP_SIZE
OMNIX_USERNAME=$USERNAME
OMNIX_TIMEZONE=$TIMEZONE
OMNIX_LAN_SUBNET=$LAN_SUBNET
OMNIX_EXTRAS=$EXTRAS
OMNIX_FULL_NAME=$FULL_NAME
OMNIX_EMAIL=$EMAIL
EOF
sudo chmod 644 "$ENV_FILE"

REPO="$HOME/.local/share/omnix"

if [ ! -d "$REPO" ]; then
  echo "==> Cloning flake into $REPO"
  mkdir -p "$HOME/.local/share"
  git clone https://github.com/galleb/omnix.git "$REPO"

  # Custom host? Create its directory from scratch — pure heredoc, no
  # cp+sed. The default.nix written here is the same shape as the
  # default hosts in the repo (reads ./variables.nix, hostName from
  # specialArgs). variables.nix is the user-tunable contract.
  if [ ! -d "$REPO/hosts/$HOST" ]; then
    echo "==> Custom host '$HOST': creating hosts/$HOST from scratch"
    mkdir -p "$REPO/hosts/$HOST"

    cat > "$REPO/hosts/$HOST/default.nix" <<'NIX'
{ config, lib, pkgs, hostName, ... }:
# Per-host config. All values come from ./variables.nix; hostName
# comes from flake.nix specialArgs (= the directory name). Add any
# host-specific Nix here that doesn't fit the variables.nix schema
# — an extra service, a one-off package list, an override.
let
  vars = import ./variables.nix;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostName;

  omnix.profile.extras     = vars.extras;
  omnix.profile.bios       = vars.bootMode == "bios";
  omnix.profile.biosDevice = vars.biosDevice or "/dev/sda";

  swapDevices = [
    { device = "/swapfile"; size = vars.swapSize; }   # MiB
  ];
}
NIX
  fi

  echo "==> Writing $REPO/hosts/$HOST/variables.nix"
  cat > "$REPO/hosts/$HOST/variables.nix" <<EOF
{
  username  = "$USERNAME";
  timeZone  = "$TIMEZONE";
  lanSubnet = "$LAN_SUBNET";
  extras    = $EXTRAS;

  profile    = "$PROFILE";

  bootMode   = "$BOOT_MODE";
  biosDevice = "$BIOS_DEVICE";
  swapSize   = $SWAP_SIZE;

  fullName  = "$FULL_NAME";
  email     = "$EMAIL";
}
EOF
else
  echo "==> $REPO already exists — skipping clone and variables.nix write."
  echo "    (To re-apply with new values, 'rm -rf $REPO' first.)"
fi

echo "==> Copying /etc/nixos/hardware-configuration.nix into the repo"
sudo cp /etc/nixos/hardware-configuration.nix \
  "$REPO/hosts/$HOST/hardware-configuration.nix"
sudo chown "$USER:users" "$REPO/hosts/$HOST/hardware-configuration.nix"

# Stage hosts/$HOST/ so that 'nixos-rebuild --flake' sees the new
# files. git+file:// flake sources copy only tracked files into the
# Nix store; untracked files are invisible. Without this the freshly
# created hosts/<custom>/ directory wouldn't show up in
# builtins.readDir ./hosts inside flake.nix, and nixosConfigurations
# wouldn't include the new host. 'git add' doesn't need a user
# identity (commit does, add doesn't).
echo "==> Staging hosts/$HOST/ for the flake evaluation"
git -C "$REPO" add "hosts/$HOST/" 2>/dev/null || true

echo "==> Running nixos-rebuild boot --flake .#$HOST"
cd "$REPO"
sudo nixos-rebuild boot --flake ".#$HOST"

echo
read -rp "Reboot now? (Y/n): " REBOOT </dev/tty
if [[ ! "$REBOOT" =~ ^[Nn]$ ]]; then
  sudo reboot
fi
