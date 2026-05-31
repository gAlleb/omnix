{ config, lib, pkgs, username, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "storage"
      "input"
      "networkmanager"
      "docker"
      "render"
      # Группы "mpd" и "transmission" появятся только если включить
      # services.mpd / services.transmission на системном уровне.
      # Сейчас mpd работает как user-service внутри сессии mango.
    ];
    shell = pkgs.bash;
  };

  programs.bash.completion.enable = true;

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
}
