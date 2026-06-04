{ hostName, ... }:
{
  imports = [
    ../../hosts/${hostName}
    ../../modules/system
    ../../modules/drivers
  ];

  # No PRIME on a desktop — the NVIDIA card drives the display directly.
  # CPU vendor (Intel or AMD) doesn't matter for the GPU stack here.
  drivers.nvidia.enable = true;
}
