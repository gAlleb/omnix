{
  # Bootstrap-параметры — переписываются install/phase2-system.sh.
  # Если форкаешь репо: эти значения — дефолты, под которые исходно
  # был собран репо. После установки на машине пользователя phase2
  # перезапишет файл новыми ответами.
  username  = "stefan";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = true;

  profile   = "intel-laptop";

  # Boot loader: "uefi" (default for modern laptops) or "bios".
  bootMode   = "uefi";
  biosDevice = "/dev/sda";   # ignored unless bootMode = "bios"

  # Swap file size in MiB. 8 GiB lets hibernation work on most setups.
  swapSize = 8192;

  fullName  = "galleb";
  email     = "s@omfm.ru";
}
