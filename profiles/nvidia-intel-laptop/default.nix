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

  drivers.intel.enable  = true;
  drivers.nvidia.enable = true;
  drivers.nvidia-prime = {
    enable      = true;
    igpuVendor  = "intel";
    igpuBusID   = vars.igpuBusID   or "PCI:0:2:0";
    nvidiaBusID = vars.nvidiaBusID or "PCI:1:0:0";
  };
  drivers.laptop.enable = true;
}
