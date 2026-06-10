{ lib, ... }:
{
  options.omnix.profile = {
    # Hardware drivers (intel, amd, laptop, vm) have moved to
    # config.drivers.<x>.enable — see modules/drivers/. Profiles in
    # profiles/<x>/default.nix flip those on.

    bios = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Legacy BIOS / MBR install (no EFI). Switches the GRUB loader
        to install on a raw device (omnix.profile.biosDevice) instead
        of an EFI System Partition.
      '';
    };

    biosDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = "Disk to install GRUB on when omnix.profile.bios = true.";
    };

    bootLoader = lib.mkOption {
      type = lib.types.enum [ "grub" "systemd-boot" ];
      default = "grub";
      description = ''
        UEFI boot loader: "grub" (default, universal, supports BIOS
        chainload of Windows via os-prober) or "systemd-boot" (smaller,
        auto-detects any other UEFI OS that has its .efi in the same
        ESP — handy for Linux+Linux dual-boot).
        Ignored on BIOS hosts — GRUB is always used there.
      '';
    };

    efiSysMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/boot";
      description = ''
        Where the EFI System Partition is mounted. Default "/boot"
        (the ESP holds the NixOS kernels). Set to "/boot/efi" for a
        small inherited ESP (e.g. a ~100 MiB Windows ESP): GRUB's EFI
        binary is written there while the kernels live on the ext4
        root's /boot. UEFI + GRUB only — systemd-boot needs the
        kernels inside the ESP. Ignored on BIOS hosts.
      '';
    };
  };

  # Опциональные наборы приложений. Значения приходят из
  # hosts/<host>/variables.nix (блок `apps = { … }`) — маппинг живёт в
  # modules/system/apps.nix. Объявлены опциями (а не читаются напрямую),
  # чтобы любой другой модуль мог спросить config.omnix.apps.<группа>.
  options.omnix.apps = {
    gaming    = lib.mkEnableOption "Steam + gamescope + mangohud";
    comms     = lib.mkEnableOption "vesktop, telegram-desktop, gajim, senpai";
    browsers  = lib.mkEnableOption "brave (zen ставится всегда)";
    media     = lib.mkEnableOption "vlc, obs-studio, audacity, flacon, puddletag";
    office    = lib.mkEnableOption "obsidian, foliate, papers, nextcloud-client, gearlever";
    net       = lib.mkEnableOption "transmission, filezilla, remmina";
    ocr       = lib.mkEnableOption "gimagereader + tesseract";
    syncthing = lib.mkEnableOption "Syncthing";
  };
}
