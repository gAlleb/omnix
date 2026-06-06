{ config, lib, pkgs, username, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./tmux.nix
    ./gtk.nix
    ./xcompose.nix
    ./dotfiles.nix
    ./packages.nix
    ./xdg.nix
    ./photogimp.nix
    ./mpd.nix
    ./xresources.nix
   #./rclone.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  # home-manager (master) tracks ahead of nixos-unstable by one minor;
  # silence the noisy "Using mismatched versions" warning on rebuild.
  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;
}
