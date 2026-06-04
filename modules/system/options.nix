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

    extras = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Включает тяжёлые опциональные приложения — браузеры (brave,
        chromium), мессенджеры (telegram-desktop, vesktop, gajim),
        медиа (vlc, mpv, strawberry, audacity, obs-studio), OCR
        (tesseract + gimagereader) и прочий софт, который не всегда
        нужен (особенно на голой тест-ВМ).
      '';
    };
  };
}
