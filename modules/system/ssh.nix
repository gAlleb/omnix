{ config, lib, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      # PasswordAuthentication stays on for the bring-up. After you've
      # pushed an SSH public key to ~/.ssh/authorized_keys, flip this
      # to false (or set it per-user via authorizedKeys below) for a
      # tighter setup.
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    # openFirewall = true; here would put port 22 into networking.firewall
    # allowedTCPPorts, and the nixos-fw chain processes those BEFORE
    # extraInputRules. That means our `iifname "ygg0" drop` rule would
    # fire too late and SSH would be reachable over yggdrasil.
    # We open 22 manually in modules/system/networking.nix
    # (extraInputRules: `tcp dport 22 accept`) AFTER the ygg0 drop.
    openFirewall = false;
  };

  # Drop SSH public keys here later to log in without a password:
  #
  #   users.users.<username>.openssh.authorizedKeys.keys = [
  #     "ssh-ed25519 AAAA... your-key"
  #   ];
}
