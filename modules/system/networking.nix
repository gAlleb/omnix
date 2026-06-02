{ config, lib, pkgs, hostName, ... }:
let
  inherit (import ../../hosts/${hostName}/variables.nix) lanSubnet;
in
{
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  services.yggdrasil = {
    enable = true;
    # Keys generated once on first start and kept in /var/lib/yggdrasil/.
    # The yggdrasil address is derived from the public key, so this
    # gives us a stable address across reboots AND rebuilds.
    # To rotate manually: delete the persisted state file under
    # /var/lib/yggdrasil/ and `systemctl restart yggdrasil`.
    persistentKeys = true;
    settings = {
      IfName = "ygg0";
      IfMTU = 1280;
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
      ip saddr ${lanSubnet} accept
      tcp dport 22 accept
    '';
  };
}
