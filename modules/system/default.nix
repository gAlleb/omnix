{ config, lib, pkgs, ... }:
{
  imports = [
    ./options.nix
    ./boot.nix
    ./networking.nix
    ./mihomo.nix
    ./apps.nix
    ./locale.nix
    ./users.nix
    ./audio.nix
    ./bluetooth.nix
    ./desktop.nix
    ./fonts.nix
    ./docker.nix
    ./services.nix
    ./filesystems.nix
    #./filesystems-autofs.nix
    ./packages.nix
    ./nix.nix
    ./ssh.nix
    ./dwm-session.nix
  ];
}
