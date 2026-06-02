{ config, lib, pkgs, ... }:
let
  inherit (import ./variables.nix) extras;
in
{
  imports = [
    # Replaced at install time by a copy of
    # /etc/nixos/hardware-configuration.nix (see INSTALL.md).
    # The in-repo file is only a stub for `nix flake check`.
    ./hardware-configuration.nix
  ];

  networking.hostName = "omnix-vm";

  # VM guest services (qemu-guest-agent, spice) come in via the "vm"
  # profile this host is mapped to in flake.nix:
  # profile = "vm" → drivers.vm.enable.

  omnix.profile.extras = extras;

  # Proxmox VM was provisioned with SeaBIOS / legacy boot; flip this to
  # false (or just remove) if you re-create the VM with OVMF/UEFI.
  omnix.profile.bios = true;
  omnix.profile.biosDevice = "/dev/sda";

  # 4 GiB swapfile. NixOS creates /swapfile on `nixos-rebuild switch`
  # via systemd-makefs, formats it, and turns swap on automatically.
  # Eats ~30 s on first rebuild while the file is allocated.
  # Drop or shrink if the VM has plenty of RAM.
  swapDevices = [
    { device = "/swapfile"; size = 4096; }   # size in MiB
  ];
}
