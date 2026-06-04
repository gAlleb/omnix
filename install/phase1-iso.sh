#!/usr/bin/env bash
#
# omnix install — phase 1 (runs on the NixOS minimal ISO, as root).
#
# Prereq: target disk partitioned + /mnt mounted (and /mnt/boot for UEFI).
# This script asks a few questions, runs `nixos-generate-config --root /mnt`,
# writes a minimal `/mnt/etc/nixos/configuration.nix` that boots into a
# bare system with git + SSH + your user, and drops
# `/mnt/etc/omnix-install.env` for phase 2 to read.
#
# When it finishes, run:
#   sudo nixos-install --no-root-passwd
#   sudo reboot
#
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "phase1 must run as root (use sudo)" >&2
  exit 1
fi

if ! mountpoint -q /mnt; then
  echo "/mnt is not a mount point — partition + mount your target disk first" >&2
  exit 1
fi

# All `read` calls go to /dev/tty so the script works when piped via
# `curl … | sudo bash` — without this, read steals stdin from the pipe
# and eats the next lines of the script itself.
ask() {
  local prompt="$1" default="$2" var
  read -rp "$prompt [$default]: " var </dev/tty
  echo "${var:-$default}"
}

# Auto-detect GPU + form factor to suggest the right default host.
# GPU detection uses lspci (in pciutils, present on the minimal ISO).
# Form-factor uses battery presence as the primary signal, with DMI
# chassis_type as a fallback for odd hardware. We detect the integrated
# GPU vendor (intel/amd/vm) and the presence of a discrete NVIDIA dGPU
# separately, so we can suggest a hybrid host (nvidia-intel-laptop /
# nvidia-amd-laptop) when both are present.
DETECTED_GPU=unknown
HAS_NVIDIA=false
if command -v lspci >/dev/null 2>&1; then
  if   lspci 2>/dev/null | grep -qiE 'virtio.*(display|vga)|vmware|qemu'; then
    DETECTED_GPU=vm
  elif lspci 2>/dev/null | grep -qiE '(vga|3d).*intel'; then
    DETECTED_GPU=intel
  elif lspci 2>/dev/null | grep -qiE '(vga|3d).*(amd|ati|advanced micro)'; then
    DETECTED_GPU=amd
  fi
  lspci 2>/dev/null | grep -qiE '(vga|3d).*nvidia' && HAS_NVIDIA=true
fi

DETECTED_FORM=desktop
if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
  DETECTED_FORM=laptop
elif [ -r /sys/class/dmi/id/chassis_type ]; then
  # 9/10/14 = laptop, notebook, sub-notebook
  case "$(cat /sys/class/dmi/id/chassis_type)" in
    9|10|14) DETECTED_FORM=laptop ;;
  esac
fi

if [ "$HAS_NVIDIA" = "true" ]; then
  if [ "$DETECTED_FORM" = "laptop" ]; then
    case "$DETECTED_GPU" in
      intel) DETECTED_HOST=omnix-nvidia-intel-laptop ;;
      amd)   DETECTED_HOST=omnix-nvidia-amd-laptop   ;;
      *)     DETECTED_HOST=omnix-nvidia-desktop      ;;  # nvidia-only laptop, rare
    esac
  else
    DETECTED_HOST=omnix-nvidia-desktop
  fi
else
  case "$DETECTED_GPU" in
    vm)    DETECTED_HOST=omnix-vm ;;
    intel) DETECTED_HOST=omnix-intel-$DETECTED_FORM ;;
    amd)   DETECTED_HOST=omnix-amd-$DETECTED_FORM ;;
    *)     DETECTED_HOST=omnix-vm ;;
  esac
fi

# Convert an lspci bus address like "01:00.0" or "0a:00.0" to the
# PCI:D:S:F form NVIDIA PRIME wants. Hex → decimal for bus/slot.
pci_addr_to_bus_id() {
  local addr="$1"
  [ -n "$addr" ] || return 0
  local d="${addr%%:*}"
  local rest="${addr#*:}"
  local s="${rest%%.*}"
  local f="${rest#*.}"
  printf 'PCI:%d:%d:%d' "$((16#$d))" "$((16#$s))" "$f"
}

# For nvidia-*-laptop hosts: auto-detect the two PCI bus IDs PRIME
# needs. Falls back to placeholders if lspci doesn't find a match —
# user can override at the BusID prompt or fix variables.nix later.
DETECTED_NVIDIA_BUS_ID="PCI:1:0:0"
DETECTED_IGPU_BUS_ID="PCI:0:2:0"
if [ "$HAS_NVIDIA" = "true" ] && command -v lspci >/dev/null 2>&1; then
  nv_addr=$(lspci 2>/dev/null | grep -iE '(vga|3d).*nvidia' | head -1 | awk '{print $1}')
  [ -n "$nv_addr" ] && DETECTED_NVIDIA_BUS_ID=$(pci_addr_to_bus_id "$nv_addr")
  case "$DETECTED_GPU" in
    intel)
      igpu_addr=$(lspci 2>/dev/null | grep -iE '(vga|3d).*intel' | head -1 | awk '{print $1}')
      ;;
    amd)
      igpu_addr=$(lspci 2>/dev/null | grep -iE '(vga|3d).*(amd|ati|advanced micro)' | head -1 | awk '{print $1}')
      ;;
    *) igpu_addr="" ;;
  esac
  [ -n "$igpu_addr" ] && DETECTED_IGPU_BUS_ID=$(pci_addr_to_bus_id "$igpu_addr")
fi

cat <<EOF

Detected: GPU=$DETECTED_GPU, form=$DETECTED_FORM → suggested host: $DETECTED_HOST

Pick one of the default hosts (recommended), or type any other name
to create a CUSTOM host — phase2 will then copy the appropriate
default host as a template and rename it.

Default hosts:
  omnix-vm                    — Proxmox / QEMU virtual machine
  omnix-intel-laptop          — Intel iGPU laptop (TLP, brightness)
  omnix-intel-desktop         — Intel iGPU desktop
  omnix-amd-laptop            — AMD GPU laptop (TLP, brightness)
  omnix-amd-desktop           — AMD GPU desktop
  omnix-nvidia-intel-laptop   — Intel CPU + NVIDIA dGPU laptop (PRIME)
  omnix-nvidia-amd-laptop     — AMD CPU + NVIDIA dGPU laptop (PRIME)
  omnix-nvidia-desktop        — Discrete NVIDIA desktop (any CPU)
EOF
HOST=$(ask "Host name" "$DETECTED_HOST")

# Validate hostname (Linux/Nix-attr-friendly)
if [[ ! "$HOST" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid host name '$HOST' — use lowercase letters, digits and hyphens only." >&2
  exit 1
fi

case "$HOST" in
  omnix-vm|omnix-intel-laptop|omnix-intel-desktop|omnix-amd-laptop|omnix-amd-desktop|omnix-nvidia-intel-laptop|omnix-nvidia-amd-laptop|omnix-nvidia-desktop)
    # Default host — profile name is derived by stripping the "omnix-" prefix.
    PROFILE="${HOST#omnix-}"
    ;;
  *)
    # Custom host — ask which profile (drivers + system stack) to base it on.
    DEFAULT_PROFILE=${DETECTED_HOST#omnix-}
    echo ""
    echo "Custom host '$HOST'. Which hardware profile should it use?"
    echo "  vm | intel-laptop | intel-desktop | amd-laptop | amd-desktop"
    echo "  nvidia-intel-laptop | nvidia-amd-laptop | nvidia-desktop"
    PROFILE=$(ask "Profile" "$DEFAULT_PROFILE")
    case "$PROFILE" in
      vm|intel-laptop|intel-desktop|amd-laptop|amd-desktop|nvidia-intel-laptop|nvidia-amd-laptop|nvidia-desktop) ;;
      *) echo "Unknown profile: $PROFILE" >&2; exit 1 ;;
    esac
    ;;
esac

# For nvidia-*-laptop profiles PRIME needs the two PCI bus IDs. Ask
# for them with autodetected defaults; user can override. Skipped
# for non-PRIME profiles (their variables.nix will not include the
# fields and the profile's `or` fallback covers the absence).
IGPU_BUS_ID=""
NVIDIA_BUS_ID=""
case "$PROFILE" in
  nvidia-intel-laptop|nvidia-amd-laptop)
    echo ""
    echo "NVIDIA PRIME needs the iGPU and dGPU PCI bus IDs (D:S:F form)."
    echo "Run 'lspci | grep -E \"VGA|3D\"' to verify if the autodetected"
    echo "values look wrong (bus 01:00.0 → PCI:1:0:0)."
    IGPU_BUS_ID=$(ask  "iGPU bus ID"   "$DETECTED_IGPU_BUS_ID")
    NVIDIA_BUS_ID=$(ask "NVIDIA bus ID" "$DETECTED_NVIDIA_BUS_ID")
    ;;
esac

# Auto-detect boot mode the same way phase2 does: presence of
# /sys/firmware/efi/efivars is authoritative proof the kernel booted
# UEFI. Works on the install ISO too — if the VM/machine firmware is
# SeaBIOS the ISO comes up in BIOS mode and this caches the right
# default for the prompt.
DETECTED_BOOT=uefi
if [ ! -d /sys/firmware/efi/efivars ]; then
  DETECTED_BOOT=bios
fi
BOOT=$(ask "Boot mode (uefi | bios)" "$DETECTED_BOOT")
case "$BOOT" in
  uefi|bios) ;;
  *) echo "Unknown boot mode: $BOOT" >&2; exit 1 ;;
esac

DISK=""
if [ "$BOOT" = "bios" ]; then
  DISK=$(ask "Disk device for GRUB" "/dev/sda")
fi

# Swap size in MiB. VM defaults to 4 GiB; everything else to 8 GiB.
case "$PROFILE" in
  vm) DEFAULT_SWAP=4096 ;;
  *)  DEFAULT_SWAP=8192 ;;
esac
SWAP_SIZE=$(ask "Swap size in MiB" "$DEFAULT_SWAP")
if [[ ! "$SWAP_SIZE" =~ ^[0-9]+$ ]] || [ "$SWAP_SIZE" -lt 0 ]; then
  echo "Invalid swap size: $SWAP_SIZE" >&2; exit 1
fi

USERNAME=$(ask "Username" "stefan")
TIMEZONE=$(ask "Timezone" "Europe/Moscow")
LAN_SUBNET=$(ask "LAN subnet allowed through firewall" "192.168.1.0/24")

read -rp "Install heavy extras (brave, chromium, vlc, obs, …)? (y/N): " EXTRAS_ANS </dev/tty
if [[ "$EXTRAS_ANS" =~ ^[Yy]$ ]]; then EXTRAS=true; else EXTRAS=false; fi

FULL_NAME=$(ask "Full name for git commits" "$USERNAME")
EMAIL=$(ask "Email for git commits" "$USERNAME@$HOST")

while true; do
  read -srp "Initial password for $USERNAME: " PW1 </dev/tty; echo
  read -srp "Confirm: " PW2 </dev/tty; echo
  if [ -n "$PW1" ] && [ "$PW1" = "$PW2" ]; then break; fi
  echo "Passwords didn't match (or empty), try again."
done

echo
echo "==> Running nixos-generate-config --root /mnt"
nixos-generate-config --root /mnt

echo "==> Hashing password with mkpasswd"
HASHED_PW=$(printf '%s' "$PW1" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 -s")
unset PW1 PW2

# Boot loader block — UEFI vs BIOS
if [ "$BOOT" = "uefi" ]; then
  BOOT_BLOCK='  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;'
else
  BOOT_BLOCK="  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = \"$DISK\";
    efiSupport = false;
    useOSProber = true;
  };"
fi

# Keep whatever stateVersion nixos-generate-config picked.
STATE_VERSION=$(grep -oP 'system\.stateVersion\s*=\s*"\K[^"]+' \
  /mnt/etc/nixos/configuration.nix 2>/dev/null || echo "25.05")

echo "==> Writing /mnt/etc/nixos/configuration.nix"
cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

$BOOT_BLOCK

  networking.hostName = "$HOST";
  networking.networkmanager.enable = true;

  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "$HASHED_PW";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    openFirewall = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "$STATE_VERSION";
}
EOF

echo "==> Writing /mnt/etc/omnix-install.env (for phase 2)"
cat > /mnt/etc/omnix-install.env <<EOF
OMNIX_HOST=$HOST
OMNIX_PROFILE=$PROFILE
OMNIX_BOOT_MODE=$BOOT
OMNIX_BIOS_DEVICE=$DISK
OMNIX_SWAP_SIZE=$SWAP_SIZE
OMNIX_IGPU_BUS_ID=$IGPU_BUS_ID
OMNIX_NVIDIA_BUS_ID=$NVIDIA_BUS_ID
OMNIX_USERNAME=$USERNAME
OMNIX_TIMEZONE=$TIMEZONE
OMNIX_LAN_SUBNET=$LAN_SUBNET
OMNIX_EXTRAS=$EXTRAS
OMNIX_FULL_NAME=$FULL_NAME
OMNIX_EMAIL=$EMAIL
EOF
chmod 644 /mnt/etc/omnix-install.env

echo
read -rp "Run 'nixos-install --no-root-passwd' now? (Y/n): " RUN_INSTALL </dev/tty
if [[ ! "$RUN_INSTALL" =~ ^[Nn]$ ]]; then
  nixos-install --no-root-passwd
  echo
  read -rp "Reboot now? (Y/n): " RUN_REBOOT </dev/tty
  if [[ ! "$RUN_REBOOT" =~ ^[Nn]$ ]]; then
    reboot
  fi
fi

cat <<EOF

Phase 1 done.

After reboot, log in as $USERNAME and run phase 2:
  curl -L https://raw.githubusercontent.com/galleb/omnix/refs/heads/main/install/phase2-system.sh | bash
EOF
