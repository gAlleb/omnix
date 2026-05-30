{ config, lib, pkgs, ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  programs.nm-applet.enable = true;
}
