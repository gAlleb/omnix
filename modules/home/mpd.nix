{ config, lib, pkgs, ... }:
let
  mpdConf = "${config.home.homeDirectory}/.config/mpd/mpd.conf";
in
{
  # ── mpd ─────────────────────────────────────────────────────────────────
  # Запускается как user-level systemd unit, читает наш конфиг из репо
  # (symlink ~/.config/mpd -> config/mpd ставится через dotfiles.nix).
  # Не используем модуль home-manager `services.mpd`, потому что он
  # генерирует свой mpd.conf в /nix/store и затирает symlink.
  systemd.user.services.mpd = {
    Unit = {
      Description = "Music Player Daemon (omnix)";
      Documentation = [ "man:mpd(1)" ];
      After = [ "network.target" "sound.target" ];
    };

    Service = {
      Type = "notify";
      ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon ${mpdConf}";
      # Если notify не сработает (mpd собран без systemd-поддержки) — поменять
      # Type на "simple" и убрать --no-daemon. В nixpkgs unstable mpd идёт с
      # systemd-нотификацией, так что notify — основной путь.
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # ── mpdris2-rs ──────────────────────────────────────────────────────────
  # MPRIS2-мост для MPD, чтобы playerctl/waybar видели плеер.
  systemd.user.services.mpdris2-rs = {
    Unit = {
      Description = "MPRIS2 D-Bus bridge for MPD";
      After = [ "mpd.service" ];
      PartOf = [ "mpd.service" ];
    };

    Service = {
      ExecStart = "${pkgs.mpdris2-rs}/bin/mpdris2-rs";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # ── dunst ───────────────────────────────────────────────────────────────
  # pkgs.dunst ships dunst.service with WantedBy=default.target, which
  # makes systemd start it BEFORE mango exports WAYLAND_DISPLAY. dunst
  # then falls back to X11 and dies.
  #
  # Drop a systemd unit drop-in (~/.config/systemd/user/dunst.service.d/
  # omnix-override.conf) that:
  #   * clears WantedBy — don't autostart with default.target
  #   * adds After/PartOf=graphical-session.target — bound to the
  #     graphical session lifecycle
  # mango/autostart.conf then runs `systemctl --user start dunst.service`
  # after import-environment, which brings the service up cleanly with
  # the right env already in place.
  xdg.configFile."systemd/user/dunst.service.d/omnix-override.conf".text = ''
    [Unit]
    After=graphical-session.target
    PartOf=graphical-session.target

    [Install]
    WantedBy=
  '';
}
