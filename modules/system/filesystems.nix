{ config, lib, pkgs, username, ... }:
let
  # rclone-конфиг лежит у пользователя (через home-manager symlink).
  # Сервис запускается от root, но читает user'ский конфиг по абсолютному пути.
  userRcloneConfig = "/home/${username}/.config/rclone/rclone.conf";

  mkRcloneMount = remoteName: mountPath: {
    description = "rclone mount: ${remoteName} -> ${mountPath}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.rclone}/bin/rclone mount"
        "--config ${userRcloneConfig}"
        "--vfs-cache-mode writes"
        "--vfs-cache-max-age 24h"
        "--allow-other"
        "--umask 022"
        "--uid 1000 --gid 100"        # чтобы файлы принадлежали юзеру
        "--dir-cache-time 1000h"
        "--poll-interval 15s"
        "${remoteName}:"
        mountPath
      ];
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u ${mountPath}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
in
{
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    rclone
    cifs-utils
    nfs-utils
    ntfs3g
    exfatprogs
  ];

  services.rpcbind.enable = true;

  # ─── Network mounts via systemd.automount (NFS/CIFS/NTFS) ────────
  fileSystems = {
    # NFS
    # "/media/truenas2" = {
    #   device  = "192.168.1.14:/mnt/my-1tb-pool/music";
    #   fsType  = "nfs";
    #   options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "soft" "nofail" ];
    # };

    # CIFS — credentials file (mode 0600): username=…/password=…
    # "/media/music" = {
    #   device  = "//192.168.1.14/music";
    #   fsType  = "cifs";
    #   options = [
    #     "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"
    #     "credentials=/etc/nixos/smb-credentials"
    #     "uid=1000" "gid=100" "iocharset=utf8" "noperm" "nofail"
    #   ];
    # };

    # NTFS
    # "/media/win11-data" = {
    #   device  = "/dev/disk/by-uuid/XXXX-XXXX";
    #   fsType  = "ntfs-3g";
    #   options = [
    #     "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"
    #     "uid=1000" "gid=100" "windows_names" "nofail"
    #   ];
    # };
  };

  # ─── Cloud mounts via rclone systemd services (root-level) ───────
  # Раскомментируй и поставь свои remote-имена из rclone.conf
  # (`rclone listremotes`).
  systemd.services = {
    # rclone-googledrive = mkRcloneMount "GoogleDrive"  "/media/GoogleDrive";
    # rclone-yandex      = mkRcloneMount "YandexDisk"   "/media/YandexDisk";
  };
}
