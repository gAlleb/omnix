{ config, lib, pkgs, ... }:
{
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  services.yggdrasil = {
    enable = true;
    persistentKeys = false;
    settings = {
      IfName = "ygg0";
      Peers = [
        "tcp://ygg-msk-1.averyan.ru:8363"
        "tls://ygg-msk-1.averyan.ru:8362"
      ];
    };
  };

  networking.firewall = {
    enable = true;

    trustedInterfaces = [ "docker0" ];

    extraInputRules = ''
      iifname "ygg0" drop
      ip saddr 192.168.1.0/24 accept
      tcp dport 22 accept
    '';
  };
}
