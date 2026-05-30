{ config, lib, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];

    # Pin derivations + outputs so `nix-collect-garbage` never wipes
    # packages that belong to an active generation. Costs a bit of
    # disk; saves redownloading 7 GiB if a build aborts mid-way.
    keep-outputs = true;
    keep-derivations = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
