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
  # pkgs.dunst ships its own dunst.service user unit pulled in by
  # default.target. It starts BEFORE mango sets WAYLAND_DISPLAY, so dunst
  # falls back to X11, can't open a display, and dies. Mask the unit
  # by symlinking it to /dev/null — mango/autostart.conf launches dunst
  # via exec-once after `systemctl --user import-environment
  # WAYLAND_DISPLAY ...` runs.
  xdg.configFile."systemd/user/dunst.service".source = "/dev/null";
}
