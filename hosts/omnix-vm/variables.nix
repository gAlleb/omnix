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

  # Hardware profile — flake.nix читает это поле и подставляет в mkHost.
  profile   = "vm";

  # Boot loader: "uefi" or "bios". Default Proxmox VM is BIOS/SeaBIOS,
  # but Proxmox can also boot OVMF/UEFI — phase1 asks at install time.
  bootMode   = "bios";
  biosDevice = "/dev/sda";   # used only when bootMode = "bios"

  # Swap file size in MiB. 4 GiB sane default for a VM.
  swapSize = 4096;
  bootLoader = "grub";
  # efiSysMountPoint = "/boot/efi";  # uncomment for a small inherited ESP (Path B); default "/boot"

  # Git persona — phase2 спрашивает и тоже пишет сюда.
  fullName  = "user";
  email     = "user@localhost";
}
