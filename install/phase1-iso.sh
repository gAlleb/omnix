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
# chassis_type as a fallback for odd hardware.
DETECTED_GPU=unknown
if command -v lspci >/dev/null 2>&1; then
  if   lspci 2>/dev/null | grep -qiE 'virtio.*(display|vga)|vmware|qemu'; then
    DETECTED_GPU=vm
  elif lspci 2>/dev/null | grep -qiE '(vga|3d).*intel'; then
    DETECTED_GPU=intel
  elif lspci 2>/dev/null | grep -qiE '(vga|3d).*(amd|ati|advanced micro)'; then
    DETECTED_GPU=amd
  fi
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

case "$DETECTED_GPU" in
  vm)    DETECTED_HOST=omnix-vm ;;
  intel) DETECTED_HOST=omnix-intel-$DETECTED_FORM ;;
  amd)   DETECTED_HOST=omnix-amd-$DETECTED_FORM ;;
  *)     DETECTED_HOST=omnix-vm ;;
esac

cat <<EOF

Detected: GPU=$DETECTED_GPU, form=$DETECTED_FORM → suggested host: $DETECTED_HOST

Available default hosts:
  omnix-vm              — Proxmox / QEMU virtual machine
  omnix-intel-laptop    — Intel iGPU laptop (TLP, brightness)
  omnix-intel-desktop   — Intel iGPU desktop
  omnix-amd-laptop      — AMD GPU laptop (TLP, brightness)
  omnix-amd-desktop     — AMD GPU desktop
EOF
HOST=$(ask "Host profile" "$DETECTED_HOST")
case "$HOST" in
  omnix-vm|omnix-intel-laptop|omnix-intel-desktop|omnix-amd-laptop|omnix-amd-desktop) ;;
  *) echo "Unknown host: $HOST" >&2
     echo "(Custom hosts will be supported in a follow-up — for now pick one of the above.)" >&2
     exit 1 ;;
esac

BOOT=$(ask "Boot mode (uefi | bios)" "uefi")
case "$BOOT" in
  uefi|bios) ;;
  *) echo "Unknown boot mode: $BOOT" >&2; exit 1 ;;
esac

DISK=""
if [ "$BOOT" = "bios" ]; then
  DISK=$(ask "Disk device for GRUB" "/dev/sda")
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
  curl -L https://raw.githubusercontent.com/galleb/omvoid/omnix-mango/install/phase2-system.sh | bash
EOF
