{ config, lib, pkgs, ... }:
{
  # Equivalent of the old config/rclone.sh — autofs + rclone + cifs/nfs/ntfs.
  # We don't describe individual mounts in Nix; the mapping changes too often,
  # so /etc/autofs/auto.mymounts is shipped as an editable template (below).

  services.autofs = {
    enable = true;
    autoMaster = ''
      /media /etc/autofs/auto.mymounts --timeout 0 --ghost
    '';
  };

  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    rclone
    cifs-utils
    nfs-utils
    ntfs3g
    exfatprogs
  ];

  # /etc/autofs/auto.mymounts is shipped as an editable template:
  # systemd-tmpfiles `C` rule copies it once from the nix-store template
  # on first rebuild, then leaves it alone — your edits survive
  # subsequent `nixos-rebuild`.  Remove the file if you want the
  # template re-deployed.
  #
  # Also create the rclone-as-mount-helper symlinks autofs expects
  # (/sbin/mount.rclone, /usr/bin/rclonefs).
  systemd.tmpfiles.rules = [
    "C /etc/autofs/auto.mymounts 0644 root root - ${pkgs.writeText "auto.mymounts-template" ''
      #
      # fstype=fuse.rclonefs works, fstype=rclone does not.
      # The rclone -> /sbin/mount.rclone symlink is created by systemd-tmpfiles below.
      #
      # NTFS:
      #   win11-data -fstype=ntfs-3g,uid=1000,gid=1000,windows_names :/dev/nvme0n1p4
      #
      # CIFS:
      #   music -fstype=cifs,rw,credentials=/etc/autofs/credentials,noperm ://192.168.1.14/music
      #
      # NFS:
      #   truenas2 -rw,soft 192.168.1.14:/mnt/my-1tb-pool/music
      #
      # CLOUD:
      #   GoogleDrive -allow_other,args2env,fstype=fuse.rclonefs,config=/root/.config/rclone/rclone.conf,cache-db-purge,allow-other,vfs-cache-mode=writes :GoogleDrive:
      #   YandexDisk  -allow_other,args2env,fstype=fuse.rclonefs,config=/root/.config/rclone/rclone.conf,cache-db-purge,allow-other,vfs-cache-mode=writes :YandexDiskLinux:
    ''}"
    "L+ /sbin/mount.rclone - - - - ${pkgs.rclone}/bin/rclone"
    "L+ /usr/bin/rclonefs   - - - - ${pkgs.rclone}/bin/rclone"
  ];

  services.rpcbind.enable = true;
}
