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

  # Switch the firewall to nftables. `networking.firewall.extraInputRules`
  # is nftables-only — in iptables (legacy) mode it's silently ignored,
  # which means both our `iifname "ygg0" drop` and the explicit SSH
  # accept never apply. With nftables on, the rule order in
  # extraInputRules is what actually wins.
  # Docker keeps working: NixOS configures docker to talk to nftables
  # via the iptables-nft shim automatically.
  networking.nftables.enable = true;

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
