{
  username  = "user";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = false;

  profile   = "amd-desktop";

  bootMode   = "uefi";
  biosDevice = "/dev/sda";

  swapSize = 8192;
  bootLoader = "grub";

  fullName  = "user";
  email     = "user@localhost";
}
