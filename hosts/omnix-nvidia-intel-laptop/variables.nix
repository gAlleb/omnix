{
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

  profile   = "nvidia-intel-laptop";

  bootMode   = "uefi";
  biosDevice = "/dev/sda";

  swapSize = 8192;
  bootLoader = "grub";
  # efiSysMountPoint = "/boot/efi";  # uncomment for a small inherited ESP (Path B); default "/boot"

  # PRIME bus IDs — auto-detected by phase1 if available, otherwise
  # placeholders. Find with `lspci | grep -E 'VGA|3D'` and convert
  # bus address `01:00.0` → `PCI:1:0:0`.
  igpuBusID   = "PCI:0:2:0";
  nvidiaBusID = "PCI:1:0:0";

  fullName  = "user";
  email     = "user@localhost";
}
