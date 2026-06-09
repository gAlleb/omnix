{ config, lib, pkgs, username, ... }:
# Optional application groups, declared as options.omnix.apps.* (see
# options.nix). Each host's default.nix forwards its variables.nix
# toggles into these options (omnix.apps = vars.apps or {};), the same
# place omnix.profile.* is wired — so this module is a pure consumer of
# config.omnix.apps and never reads variables.nix itself.
#
# Most groups are plain package lists installed system-wide. Steam and
# Syncthing are system-level (FHS wrapper / 32-bit libs / a service), so
# they live here as real config rather than in a package list.
let
  cfg = config.omnix.apps;
in
{
  environment.systemPackages = with pkgs;
    lib.optionals cfg.comms    [ vesktop telegram-desktop gajim senpai ]
    ++ lib.optionals cfg.browsers [ brave ]
    ++ lib.optionals cfg.media    [ vlc obs-studio audacity flacon puddletag ]
    ++ lib.optionals cfg.office   [ obsidian foliate papers nextcloud-client gearlever ]
    ++ lib.optionals cfg.net      [ transmission_4-gtk filezilla remmina ]
    ++ lib.optionals cfg.ocr      [ gimagereader tesseract ]
    ++ lib.optionals cfg.gaming   [ mangohud gamescope ];

  programs.steam = lib.mkIf cfg.gaming {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };

  services.syncthing = lib.mkIf cfg.syncthing {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";
    openDefaultPorts = true;
  };
}
