{
  username  = "user";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = false;

  profile   = "nvidia-intel-laptop";

  bootMode   = "uefi";
  biosDevice = "/dev/sda";

  swapSize = 8192;

  # PRIME bus IDs — auto-detected by phase1 if available, otherwise
  # placeholders. Find with `lspci | grep -E 'VGA|3D'` and convert
  # bus address `01:00.0` → `PCI:1:0:0`.
  igpuBusID   = "PCI:0:2:0";
  nvidiaBusID = "PCI:1:0:0";

  fullName  = "user";
  email     = "user@localhost";
}
