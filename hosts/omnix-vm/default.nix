{ config, lib, pkgs, ... }:
{
  imports = [
    # See hosts/omnix/default.nix for the rationale.
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hardware-configuration.nix)
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
