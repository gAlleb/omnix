{ config, lib, pkgs, ... }:
{
  home.file.".config/mpv/scripts/mpris.so".source =
    "${pkgs.mpvScripts.mpris}/share/mpv/scripts/mpris.so";

  home.file.".config/mpv/scripts/notify-send.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.local/share/omnix/config/mpv/scripts/notify-send.lua";

  home.file.".config/mpv/scripts/icy-notify.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.local/share/omnix/config/mpv/scripts/icy-notify.lua";
}
