{ lib, ... }:
{
  options.omnix.profile = {
    laptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Включает TLP, udev-правило AC-плага, brightnessctl и прочие батарейные штуки.";
    };

    intel = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Включает intel-media-driver и микрокод Intel.";
    };

    vm = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Хост — виртуалка (Proxmox/qemu). Отключает железо-специфичные модули.";
    };

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
