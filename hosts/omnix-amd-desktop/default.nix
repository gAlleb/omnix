{ config, lib, pkgs, hostName, ... }:
# Per-host config. All values come from ./variables.nix; hostName
# comes from flake.nix specialArgs (= the directory name). If you
# need anything host-specific that doesn't fit the variables.nix
# schema (an extra service, a one-off package list, an override),
# add it here — this file is the escape hatch.
let
  vars = import ./variables.nix;
in
{
  imports = [
    # Replaced at install time by a copy of
    # /etc/nixos/hardware-configuration.nix (see INSTALL.md).
    # The in-repo file is only a stub for `nix flake check`.
    ./hardware-configuration.nix
  ];

  networking.hostName = hostName;

  omnix.profile.bios       = vars.bootMode == "bios";
  omnix.profile.biosDevice = vars.biosDevice or "/dev/sda";
  omnix.profile.bootLoader = vars.bootLoader or "grub";

  # Optional app groups — forwarded into options.omnix.apps.* (see
  # modules/system/apps.nix). Missing/partial `apps` block → off.
  omnix.apps = vars.apps or {};

  swapDevices = [
    { device = "/swapfile"; size = vars.swapSize; }   # MiB
  ];
}
