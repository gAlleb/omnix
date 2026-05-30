{ config, lib, pkgs, ... }:
{
  imports = [
    # Replaced at install time by a copy of
    # /etc/nixos/hardware-configuration.nix (see INSTALL.md).
    # The in-repo file is only a stub for `nix flake check`.
    ./hardware-configuration.nix
  ];

  networking.hostName = "omnix-vm";

  omnix.profile.laptop = false;
  omnix.profile.intel = false;
  omnix.profile.vm = true;

  # Proxmox VM was provisioned with SeaBIOS / legacy boot; flip this to
  # false (or just remove) if you re-create the VM with OVMF/UEFI.
  omnix.profile.bios = true;
  omnix.profile.biosDevice = "/dev/sda";

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
