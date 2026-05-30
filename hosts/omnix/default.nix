{ config, lib, pkgs, ... }:
{
  imports = [
    # Replaced at install time by a copy of
    # /etc/nixos/hardware-configuration.nix (see INSTALL.md).
    # The in-repo file is only a stub for `nix flake check`.
    ./hardware-configuration.nix
  ];

  networking.hostName = "omnix";

  # Real laptop profile — enables TLP, intel GPU drivers and udev
  # power-event rule from modules/system/{power,desktop}.nix.
  omnix.profile.laptop = true;
  omnix.profile.intel = true;
  omnix.profile.vm = false;
}
