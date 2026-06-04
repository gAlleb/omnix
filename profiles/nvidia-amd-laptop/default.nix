{ hostName, ... }:
let
  vars = import (../../hosts + "/${hostName}/variables.nix");
in
{
  imports = [
    ../../hosts/${hostName}
    ../../modules/system
    ../../modules/drivers
  ];

  drivers.amd.enable    = true;
  drivers.nvidia.enable = true;
  drivers.nvidia-prime = {
    enable      = true;
    igpuVendor  = "amd";
    igpuBusID   = vars.igpuBusID   or "PCI:5:0:0";
    nvidiaBusID = vars.nvidiaBusID or "PCI:1:0:0";
  };
  drivers.laptop.enable = true;
}
