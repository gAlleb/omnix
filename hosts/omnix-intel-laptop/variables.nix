{
  # Bootstrap-параметры — переписываются install/phase2-system.sh.
  # Если форкаешь репо: эти значения — дефолты, под которые исходно
  # был собран репо. После установки на машине пользователя phase2
  # перезапишет файл новыми ответами.
  username  = "user";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  # ── Опциональные наборы приложений ───────────────────────────
  # Поставь true и пересобери. Чего нет в списке — выключено
  # (полные списки пакетов — в modules/system/apps.nix).
  apps = {
    gaming    = false;  # Steam + gamescope + mangohud
    comms     = false;  # vesktop, telegram-desktop, gajim, senpai
    browsers  = false;  # brave (zen ставится всегда)
    media     = false;  # vlc, obs-studio, audacity, flacon, puddletag
    office    = false;  # obsidian, foliate, papers, nextcloud-client, gearlever
    net       = false;  # transmission, filezilla, remmina
    ocr       = false;  # gimagereader + tesseract
    syncthing = false;  # служба Syncthing
  };

  profile   = "intel-laptop";

  # Boot loader: "uefi" (default for modern laptops) or "bios".
  bootMode   = "uefi";
  biosDevice = "/dev/sda";   # ignored unless bootMode = "bios"

  # Swap file size in MiB. 8 GiB lets hibernation work on most setups.
  swapSize = 8192;
  bootLoader = "grub";
  # efiSysMountPoint = "/boot/efi";  # uncomment for a small inherited ESP (Path B); default "/boot"

  fullName  = "user";
  email     = "user@localhost";
}
