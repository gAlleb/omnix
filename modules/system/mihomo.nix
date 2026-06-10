{ lib, pkgs, username, ... }:
{
  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  # Stop it from starting at boot
  systemd.services.mihomo.wantedBy = lib.mkForce [ ];

  # Setup the folder and initial files
  systemd.tmpfiles.rules = [
    "d /etc/mihomo 0755 root root -"
    "C /etc/mihomo/home.yaml   0644 root root - ${../../config/mihomo/home.yaml}"
    "C /etc/mihomo/office.yaml 0644 root root - ${../../config/mihomo/office.yaml}"
    # Use L (not L+) so Nix doesn't overwrite the manual switch on every reboot
    "L /etc/mihomo/config.yaml - - - - /etc/mihomo/home.yaml"
  ];

  # This section makes script work with 'sudo' and NO password
  security.sudo.extraRules = [{
    users = [ "${username}" ];
    commands = [
      {
        command = "/run/current-system/sw/bin/systemctl start mihomo";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/systemctl stop mihomo";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/systemctl restart mihomo";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/systemctl is-active --quiet mihomo";
        options = [ "NOPASSWD" ];
      }
      {
        # Matches the '$AUTH ln -sf ...' line in the script
        command = "/run/current-system/sw/bin/ln -sf /etc/mihomo/*.yaml /etc/mihomo/config.yaml";
        options = [ "NOPASSWD" ];
      }
    ];
  }];
}
