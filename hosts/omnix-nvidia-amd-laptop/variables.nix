{
  username  = "user";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = false;

  profile   = "nvidia-amd-laptop";

  bootMode   = "uefi";
  biosDevice = "/dev/sda";

  swapSize = 8192;
  bootLoader = "grub";

  # PRIME bus IDs — auto-detected by phase1 if available, otherwise
  # placeholders. Find with `lspci | grep -E 'VGA|3D'` and convert
  # bus address `05:00.0` → `PCI:5:0:0`. On AMD APUs the iGPU often
  # sits at a higher bus number than on Intel platforms.
  igpuBusID   = "PCI:5:0:0";
  nvidiaBusID = "PCI:1:0:0";

  fullName  = "user";
  email     = "user@localhost";
}
