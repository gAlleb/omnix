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
    openFirewall = true;
  };

  # Drop SSH public keys here later to log in without a password:
  #
  #   users.users.<username>.openssh.authorizedKeys.keys = [
  #     "ssh-ed25519 AAAA... your-key"
  #   ];
}
