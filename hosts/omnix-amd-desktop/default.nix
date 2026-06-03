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

  networking.hostName = "omnix-amd-desktop";

  # Hardware drivers (amd only, no laptop power-mgmt) are turned on
  # by the "amd-desktop" profile (variables.nix → profile = "amd-desktop"):
  # drivers.amd.enable.

  omnix.profile.extras = extras;

  # 8 GiB swapfile. Adjust as needed.
  swapDevices = [
    { device = "/swapfile"; size = 8192; }   # size in MiB
  ];
}
