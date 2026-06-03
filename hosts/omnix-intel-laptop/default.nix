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

  networking.hostName = "omnix-intel-laptop";

  # Hardware drivers (intel + laptop power-mgmt) are turned on by the
  # "intel-laptop" profile (variables.nix → profile = "intel-laptop"):
  # drivers.intel.enable + drivers.laptop.enable.

  omnix.profile.extras = extras;

  # 8 GiB swapfile. Bump to >= installed RAM if you want hibernation,
  # or shrink if your SSD budget is tight. Created and turned on
  # automatically on `nixos-rebuild switch`.
  swapDevices = [
    { device = "/swapfile"; size = 8192; }   # size in MiB
  ];
}
