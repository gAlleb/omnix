{
  # Bootstrap-параметры — переписываются install/phase2-system.sh.
  # Если форкаешь репо: эти значения — дефолты, под которые исходно
  # был собран репо. После установки на машине пользователя phase2
  # перезапишет файл новыми ответами.
  username  = "user";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = false;

  # Hardware profile — flake.nix читает это поле и подставляет в mkHost.
  profile   = "vm";

  # Boot loader: "uefi" or "bios". Default Proxmox VM is BIOS/SeaBIOS,
  # but Proxmox can also boot OVMF/UEFI — phase1 asks at install time.
  bootMode   = "bios";
  biosDevice = "/dev/sda";   # used only when bootMode = "bios"

  # Swap file size in MiB. 4 GiB sane default for a VM.
  swapSize = 4096;

  # Git persona — phase2 спрашивает и тоже пишет сюда.
  fullName  = "user";
  email     = "user@localhost";
}
