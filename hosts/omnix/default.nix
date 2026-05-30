{ config, lib, pkgs, ... }:
{
  imports = [
    # Use the freshly-generated hardware-configuration from the running
    # system if it exists at the canonical /etc/nixos/ path, otherwise
    # fall back to the in-repo placeholder (sufficient for `nix flake
    # check` and for bring-up of a known-good VM).
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hardware-configuration.nix)
  ];

  networking.hostName = "omnix";

  # Real laptop profile — enables TLP, intel GPU drivers and udev
  # power-event rule from modules/system/{power,desktop}.nix.
  omnix.profile.laptop = true;
  omnix.profile.intel = true;
  omnix.profile.vm = false;
}
