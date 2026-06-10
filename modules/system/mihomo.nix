{ lib, pkgs, ... }:
# mihomo (Clash.Meta) proxy core — installed but NOT started at boot.
#
# configFile is a quoted string path, so the config lives at a mutable
# /etc path (NOT in the Nix store) and you can edit it after install.
# tmpfiles seeds a placeholder there once; the `C` rule never clobbers
# your later edits. The unit is defined but nothing pulls it in at boot,
# so start it yourself once configured: `sudo systemctl start mihomo`.
{
  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true; # only grants TUN caps to the unit; enable tun: in the yaml
    webui = pkgs.metacubexd; # dashboard served via the external-controller
  };

  systemd.services.mihomo.wantedBy = lib.mkForce [ ];

  #systemd.tmpfiles.rules = [
  #  "d /etc/mihomo 0755 root root -"
  #  "C /etc/mihomo/config.yaml 0644 root root - ${./mihomo-config.yaml}"
  #];
  systemd.tmpfiles.rules = [
    "d /etc/mihomo 0755 root root -"
    "C /etc/mihomo/home.yaml   0644 root root - ${../../config/mihomo/home.yaml}"
    "C /etc/mihomo/office.yaml 0644 root root - ${../../config/mihomo/office.yaml}"    \
    "L+ /etc/mihomo/config.yaml - - - - /etc/mihomo/home.yaml"
  ];
}
