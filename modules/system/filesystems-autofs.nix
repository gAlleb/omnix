{ config, lib, pkgs, ... }:
let
  # Создаем симлинк rclonefs в системном профиле
  rclonefs-helper = pkgs.runCommand "rclonefs-helper" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.rclone}/bin/rclone $out/bin/rclonefs
    ln -s ${pkgs.rclone}/bin/rclone $out/bin/mount.rclonefs
    ln -s ${pkgs.rclone}/bin/rclone $out/bin/mount.rclone
  '';
in
{
  services.autofs = {
    enable = true;
    autoMaster = ''
      /media /etc/autofs/auto.mymounts --timeout 0 --ghost
    '';
  };

  # Добавляем наш хелпер в окружение autofs
  systemd.services.autofs.path = [
    pkgs.rclone
    rclonefs-helper
    pkgs.fuse3
  ];

  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    rclone
    rclonefs-helper # <-- Это создаст стабильный путь /run/current-system/sw/bin/rclonefs
    cifs-utils
    nfs-utils
    ntfs3g
    exfatprogs
  ];

  systemd.tmpfiles.rules = [
    "C /etc/autofs/auto.mymounts 0644 root root - ${pkgs.writeText "auto.mymounts-template" ''
      # NTFS:
      win11-data -fstype=ntfs-3g,uid=1000,gid=1000,windows_names :/dev/nvme0n1p4

      # CIFS:
      music -fstype=cifs,rw,credentials=/etc/autofs/credentials,noperm ://192.168.1.14/music

      # NFS:
      truenas2 -rw,soft 192.168.1.14:/mnt/my-1tb-pool/music

      # CLOUD:
      # Передаем абсолютный путь к бинарнику прямо внутрь опции fstype!
      # Так mount.fuse запустит rclonefs напрямую, проигнорировав пустой PATH в bash.
      # GoogleDrive -allow_other,args2env,fstype=fuse./run/current-system/sw/bin/rclonefs,config=/root/.config/rclone/rclone.conf,cache-db-purge,allow-other,vfs-cache-mode=writes :GoogleDrive:
      # YandexDisk  -allow_other,args2env,fstype=fuse./run/current-system/sw/bin/rclonefs,config=/root/.config/rclone/rclone.conf,cache-db-purge,allow-other,vfs-cache-mode=writes :YandexDiskLinux:
    ''}"
  ];

  services.rpcbind.enable = true;
}
