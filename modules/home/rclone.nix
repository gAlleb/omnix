{ config, lib, pkgs, ... }:
let
  # Общий хелпер для одного rclone-маунта.
  # remoteName — то что в [квадратных скобках] в rclone.conf
  # mountPath — куда монтировать (создаётся через mkdir -p)
  mkRcloneMount = remoteName: mountPath: {
    Unit = {
      Description = "rclone mount: ${remoteName} -> ${mountPath}";
      After = [ "network-online.target" "sound.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.rclone}/bin/rclone mount"
        "--config ${config.home.homeDirectory}/.config/rclone/rclone.conf"
        "--vfs-cache-mode writes"
        "--vfs-cache-max-age 24h"
        "--allow-other"
        "--umask 022"
        "--dir-cache-time 1000h"
        "--poll-interval 15s"
        "${remoteName}:"
        mountPath
      ];
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u ${mountPath}";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
in
{
  # Каждый remote из ~/.config/rclone/rclone.conf становится systemd
  # user-сервисом который монтирует его при логине в Mango.
  # Список remote'ов — `rclone listremotes`.
  systemd.user.services = {
    # rclone-googledrive = mkRcloneMount "GoogleDrive"
    #   "${config.home.homeDirectory}/mnt/GoogleDrive";

    # rclone-yandex = mkRcloneMount "YandexDiskLinux"
    #   "${config.home.homeDirectory}/mnt/YandexDisk";
  };
}
